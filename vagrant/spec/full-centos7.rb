# pigsty 4-centos7-node sandbox: 2C4G + 3 x 1C2G

Specs = [
  {
    "name" => "pigsty-meta",
    "ip" => "10.10.10.10",
    "cpu" => "2", 
    "mem" => "4096", 
    "image" =>  "generic/centos7",
  },
  {
    "name" => "pigsty-node-1",
    "ip" => "10.10.10.11",
    "cpu" => "1",
    "mem" => "2048",
    "image" =>  "generic/centos7",
  },
  {
    "name" => "pigsty-node-2",
    "ip" => "10.10.10.12",
    "cpu" => "1",
    "mem" => "2048",
    "image" =>  "generic/centos7",
  },
  {
    "name" => "pigsty-node-3",
    "ip" => "10.10.10.13",
    "cpu" => "1",
    "mem" => "2048",
    "image" =>  "generic/centos7",
  },
]

## starup issue (does not affect using)
# 
# meta: SSH address: 127.0.0.1:2222
# meta: SSH username: vagrant
# meta: SSH auth method: private key
# meta: Warning: Connection reset. Retrying...
# meta: Warning: Connection aborted. Retrying...
# ......
# ==> meta: Machine booted and ready!