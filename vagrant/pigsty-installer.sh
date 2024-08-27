#!/bin/bash -e

function check_pigsty_user() {
    _new_user=${PIGSTY_USER:-'pigsty'}
    if id "$_new_user" >/dev/null 2>&1; then
        echo "info: pigsty deploy user ($_new_user) does not exist!" 1>&2
        return 1
    else
        return 0
    fi
}

function create_pigsty_user() {
    ## 为所有节点创建管理用户并可通过SSH登录所有节点的管理用户
    #> 不建议使用root账户或数据库超级用户postgres作为集群管理用户
    # 因此需要为集群的每个节点新建一个管理用户，该用户具有sudo权限。
    # 需要为所有节点(包括当前节点)配置免密登录管理用户。
    #> 需要使用root账户执行用户创建
    #> 在管理节点上登录管理用户，并配置到所有节点的免密登录。
    _new_user=${PIGSTY_USER:-'pigsty'}
    _new_uid=${PIGSTY_UID:-'1234'}

    if check_pigsty_user; then
        return 0
    fi

    _os_type=$(bash -c 'source /etc/os-release; echo $ID_LIKE')
    if [ "$_os_type" = 'debian' ]; then
        extra_groups=sudo
    else
        extra_groups=wheel
    fi
    sudo useradd "${_new_user}" \
        --create-home \
        --shell=/bin/bash \
        "--uid=$_new_uid" \
        --user-group \
        --groups $extra_groups
    #* must be run with root privilege
    echo "${_new_user} ALL=(ALL) NOPASSWD:ALL" |
        sudo tee "/etc/sudoers.d/${_new_user}"
}

function create_ssh_key() {
    # shellcheck disable=SC2016
    _new_user=${PIGSTY_USER:-'pigsty'}
    if [ ! -e "${HOME}/.ssh/id_rsa" ]; then
        ssh-keygen -f "${HOME}/.ssh/id_rsa" -N ""
    fi
}

function init_cluster_nodes(){
    _new_user=${PIGSTY_USER:-'pigsty'}
    if [ "$(whoami)" != "$_new_user" ]; then
        echo "error: current user is not pigsty administrator, please login as ${_new_user}."
        return 1
    fi
    declare -a cluster_nodes
    if [ ! -e ~/.nodes ]; then
        echo "error: cluster nodes is not defined, please specify cluster nodes in ${HOME}/.nodes."
        return 1
    else
        readarray -t cluster_nodes <<<"$(grep -Ev '^\s*#.*$' ~/.nodes)"
    fi
    if [ "${#cluster_nodes[@]}" -eq 0 ]; then
        echo "error: cluster nodes file is empty, please specify cluster nodes in ${HOME}/.nodes."
        return 0
    fi
    for _node in "${cluster_nodes[@]}"; do
        ssh-copy-id -i ~/.ssh/id_rsa.pub "$_new_user@$_node"
    done
}

function standard_install_pigsty() {
    ## 标准在线安装
    # Pigsty支持Linux内核与x86_64/amd64架构，运行于物理机、虚拟机环境中，要求使用静态IP地址。
    #> 最低配置要求为1C1G，推荐至少使用2C4G以上的机型，上不封顶，参数会自动优化适配。
    #> 使用标准安装缓存离线安装所需的软件包
    local _version=${PIGSTY_VERSION:-'2.6.0'}
    curl -fsSL https://repo.pigsty.cc/get | bash -s "${_version}"
}

function download_pigsty() {
    ## Pigsty 2.6.0
    # 离线包系统版本可选值：el{7,8,9}, debian{11,12}, ubuntu{20,22}
    ## Pigsty 2.7.0
    # 离线包系统版本可选值：el8, debian12, ubuntu22
    #> You can still perform online installation on el7, el9, debian 11 and ubuntu 20.04
    local _version=${PIGSTY_VERSION:-'2.6.0'}
    local _distro=${PIGSTY_OS_VERSION:-'el7'}
    if [ ! -e ~/.local/pigsty ]; then
        mkdir -p ~/.local ~/.cache
        set -x
        curl -sSL "https://get.pigsty.cc/v${_version}/pigsty-v${_version}.tgz" \
            -o ~/.cache/"pigsty-v${_version}.tgz"
        { set +x; } 2>/dev/null
        tar -xf ~/.cache/"pigsty-v${_version}.tgz" -C ~/.local/
    fi
    if [ ! -e /tmp/pkg.tgz ]; then
        set -x
        curl -sSL "https://get.pigsty.cc/v${_version}/pigsty-pkg-v${_version}.${_distro}.x86_64.tgz" \
            -o "/tmp/pigsty-pkg-v${_version}.${_distro}.x86_64.tgz"
        { set +x; } 2>/dev/null
        # ln -svf "/tmp/pigsty-pkg-v${_version}.${_distro}.x86_64.tgz" /tmp/pkg.tgz
        mv "/tmp/pigsty-pkg-v${_version}.${_distro}.x86_64.tgz" /tmp/pkg.tgz
    fi
}

function offline_install_pigsty() {
    cd ~/.local/pigsty
    ./bootstrap
    #> 解压 /tmp/pkg.tgz，创建并启用本地文件系统软件源，然后从中安装 Ansible
    #> 变体：如果本机有互联网访问，使用 ./bootstrap -y 可自动下载对应系统的离线软件包
    # 继续后面的配置与安装任务
    ./configure   # 执行环境检测，并生成相应的推荐配置文件，如果你知道如何配置 Pigsty 可以跳过
    ./install.yml # 根据生成的配置文件开始在当前节点上执行安装，使用离线安装包大概需要10分钟完成
}

function create_offline_repo() {
    ## 制作离线软件包仓库
    # 适用于目标操作系统离线，且没有官方发布的离线软件包仓库
    #> 官方未提供离线软件包仓库的系统可能存在依赖项冲突的问题。
    # 首先在干净系统（虚拟机）中执行标准安装
    # 然后将软件包缓存目录打包为离线软件包仓库
    bin/cache version=v2.6.0 pkg_path=/tmp/pkg.tgz repo_dir=/www/pigsty
}
