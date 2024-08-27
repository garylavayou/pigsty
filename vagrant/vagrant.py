import os, re, sys, subprocess
from typing import Dict, List, Union

def get_user_home():
    if sys.platform in ('linux', 'darwin'):
        return os.environ['HOME']
    elif sys.platform == 'win32':
        return os.environ['USERPROFILE']
    else:
        raise RuntimeError(f"{sys.platform} is not supported!")

def get_vagrant_exec():
    if sys.platform == 'linux':
        p = subprocess.run('uname -a | grep WSL', shell=True, capture_output=True, text=True)
        if p.returncode == 0:
            return 'vagrant.exe'
        else:
            return 'vagrant'
    elif sys.platform == 'win32':
        return 'vagrant.exe'
    elif sys.platform == 'darwin':
        return 'vagrant'
    else:
        raise RuntimeError(f"{sys.platform} is not supported!")
    
def parse_vagrant_spec(vagrant_filepath_or_specs:Union[str, List[Dict[str,str]]]):
    '''get the node name and ip mapping from Vagrantfile.
    
    Return
    ------
    - result: `name` to `ip` mapping.
    - specs: `(ip, name)` tuple.
    
    Note
    ----
    Pass in parsed specs object is preferred.
    '''
    specs = []
    result = {}
    if isinstance(vagrant_filepath_or_specs, list):
        for spec in vagrant_filepath_or_specs:
            if 'name' not in spec:
                raise Exception("Specs data missing 'name' field.")                
            if 'ip' not in spec:
                raise Exception("Specs data missing 'ip' field.")
            specs.append((spec['ip'], spec['name']))
            result[spec['name']] = spec['ip']
        return result, specs
    
    with open(vagrant_filepath_or_specs, 'r') as f:
        raw_lines = f.readlines()

    activate = False
    name, ip = None, None
    for line in raw_lines:
        if line.startswith('Specs'):
            activate = True
            continue
        if line.startswith(']'):
            activate = False
            break
        
        if not activate:
            continue
        # in case that the spec is written indented on multi-lines
        if "name" in line:
            name = re.findall('"name"\s*=>\s*"([^"]+)"', line)[0]
        if "ip" in line:
            ip = re.findall('"ip"\s*=>\s*"([^"]+)"', line)[0]
        if name is not None and ip is not None:
            result[name] = ip
            specs.append((ip, name))
            name, ip = None, None

    return result, specs

def read_vagrant_spec(vagrant_filepath):
    '''read vagrant specification and parsed as python dict
    
    convert the specification defined ruby code to python array.
    
    Return
    ------
    A list of node specifications, containing all defined fields including,
    `name`, `ip`, `cpu`, `mem`, ...
    '''
    with open(vagrant_filepath, 'r') as f:
        raw_lines = f.readlines()
    spec_lines = []
    spec_inside = False
    for line in raw_lines:
        if line.startswith('Specs'):
            line = line.replace('Specs = ', '')
            spec_inside = True
        if spec_inside:
            line = line.replace('=>', ':')
            spec_lines.append(line)
            if line.startswith(']'):
                break
    if len(spec_lines) == 0:
        raise Exception(f"cannot find vagrant specification in {vagrant_filepath}.")            
    # eval the expression as list of dicts
    # let python eval to parse the spec contents
    specs = eval('\n'.join(spec_lines))
    return specs