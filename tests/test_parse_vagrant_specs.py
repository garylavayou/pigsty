import unittest

class VagrantSpecsReaderTest(unittest.TestCase):
        
    def test_read_specs_indented_as_array(self):
        '''
        each spec is specified with indented format
        '''
        from vagrant.vagrant import read_vagrant_spec
        import json
        filepath = 'vagrant/spec/full-centos7.rb'
        specs = read_vagrant_spec(filepath)
        print(json.dumps(specs, indent=4))
    
    def test_read_specs_one_line_as_array(self):
        '''
        each spec is specified in one line
        '''
        from vagrant.vagrant import read_vagrant_spec
        import json
        filepath = 'vagrant/spec/full.rb'
        specs = read_vagrant_spec(filepath)
        print(json.dumps(specs, indent=4))
        
    def test_read_specs_from_vagrantfile(self):
        '''
        specs are embedded in the vagrantfile
        '''
        from vagrant.vagrant import read_vagrant_spec
        import json
        filepath = 'vagrant/Vagrantfile'
        specs = read_vagrant_spec(filepath)
        print(json.dumps(specs, indent=4))

class VagrantSpecsParserTest(unittest.TestCase):       
    def test_parse_vagrant_spec(self):
        '''
        get name and ip mapping from vagrant file.
        '''
        from vagrant.vagrant import parse_vagrant_spec, read_vagrant_spec
        from pprint import pprint
        filepath = 'vagrant/Vagrantfile'
        mapping, specs = parse_vagrant_spec(read_vagrant_spec(filepath))
        print('')
        pprint(mapping)
        pprint(specs)