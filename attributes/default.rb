include_attribute "kagent"

default['livy']['user']                    = node['install']['user'].empty? ? "livy" : node['install']['user']
default['livy']['user-home']               = "/home/#{node['livy']['user']}"

default['livy']['version']                 = "0.8.0-incubating-SNAPSHOT-bin"
default['livy']['url']                     = "#{node['download_url']}/apache-livy-#{node['livy']['version']}.zip"
default['livy']['port']                    = "8998"
default['livy']['dir']                     = node['install']['dir'].empty? ? "/srv" : node['install']['dir']
default['livy']['home']                    = node['livy']['dir'] + "/apache-livy-" + node['livy']['version']
default['livy']['base_dir']                = node['livy']['dir'] + "/apache-livy"

# Directory to store state for recovery
default['livy']['state_dir']                = "#{node['livy']['base_dir']}/state"

default['livy']['keystore']                = "#{node['kagent']['certs_dir']}/keystores/#{node['hostname']}__kstore.jks"

default['livy']['pid_file']                = "/tmp/apache-livy.pid"
default['livy']['log']                     = "#{node['livy']['base_dir']}/logs/apache-livy-logfile.log"
default['livy']['log_size']                = "20MB"

default['livy']['rsc']['rpc']['max']['size'] =  "268435456"
default['livy']['rpc']['max']['size']        =  "268435456"
