#
# Cookbook Name:: livy
# Recipe:: install
#
# Copyright 2016, Jim Dowling
#
# All rights reserved
#

include_recipe "java"

my_ip = my_private_ip()

hops_groups()

group node['livy']['group'] do
  action :create
  not_if "getent group #{node['livy']['group']}"
  not_if { node['install']['external_users'].casecmp("true") == 0 }
end

user node['livy']['user'] do
  home "/home/#{node['livy']['user']}"
  gid node['livy']['group']
  action :create
  shell "/bin/bash"
  manage_home true
  not_if "getent passwd #{node['livy']['user']}"
  not_if { node['install']['external_users'].casecmp("true") == 0 }
end

group node['kagent']['certs_group'] do
  action :modify
  members ["#{node['livy']['user']}"]
  append true
  not_if { node['install']['external_users'].casecmp("true") == 0 }
end

group node['hops']['group'] do
  action :modify
  members ["#{node['livy']['user']}"]
  append true
  not_if { node['install']['external_users'].casecmp("true") == 0 }
end


package_url = "#{node['livy']['url']}"
base_package_filename = File.basename(package_url)
cached_package_filename = "#{Chef::Config['file_cache_path']}/#{base_package_filename}"

remote_file cached_package_filename do
  source package_url
  owner "#{node['livy']['user']}"
  mode "0644"
  action :create_if_missing
end


package "unzip"

# Extract Livy
livy_downloaded = "#{node['livy']['home']}/.livy_extracted_#{node['livy']['version']}"

bash 'extract-livy' do
        user "root"
        group node['livy']['group']
        code <<-EOH
                set -e
                unzip #{cached_package_filename} -d #{Chef::Config['file_cache_path']}
                mv #{Chef::Config['file_cache_path']}/apache-livy-#{node['livy']['version']} #{node['livy']['dir']}
                # remove old symbolic link, if any
                rm -f #{node['livy']['base_dir']}
                ln -s #{node['livy']['home']} #{node['livy']['base_dir']}
                chown -R #{node['livy']['user']}:#{node['livy']['group']} #{node['livy']['home']}
                chown -R #{node['livy']['user']}:#{node['livy']['group']} #{node['livy']['base_dir']}
                chmod 750 #{node['livy']['home']}
                touch #{livy_downloaded}
                chown -R #{node['livy']['user']}:#{node['livy']['group']} #{livy_downloaded}
        EOH
     not_if { ::File.exists?( "#{livy_downloaded}" ) }
end

bash 'link-jars' do
        user "root"
        group node['livy']['group']
        code <<-EOH
                rm -f #{node['livy']['base_dir']}/rsc-jars/livy-api.jar
                rm -f #{node['livy']['base_dir']}/rsc-jars/livy-rsc.jar
                rm -f #{node['livy']['base_dir']}/rsc-jars/netty-all.jar
                ln -s #{node['livy']['base_dir']}/rsc-jars/livy-api-*.jar #{node['livy']['base_dir']}/rsc-jars/livy-api.jar
                ln -s #{node['livy']['base_dir']}/rsc-jars/livy-rsc-*jar #{node['livy']['base_dir']}/rsc-jars/livy-rsc.jar
                ln -s #{node['livy']['base_dir']}/rsc-jars/netty-all-*.jar #{node['livy']['base_dir']}/rsc-jars/netty-all.jar
                rm -f #{node['livy']['base_dir']}/repl_2.11-jars/commons-codec.jar
                rm -f #{node['livy']['base_dir']}/repl_2.11-jars/livy-core.jar
                rm -f #{node['livy']['base_dir']}/repl_2.11-jars/livy-repl.jar
                ln -s #{node['livy']['base_dir']}/repl_2.11-jars/commons-codec-*.jar #{node['livy']['base_dir']}/repl_2.11-jars/commons-codec.jar
                ln -s #{node['livy']['base_dir']}/repl_2.11-jars/livy-core_*.jar #{node['livy']['base_dir']}/repl_2.11-jars/livy-core.jar
                ln -s #{node['livy']['base_dir']}/repl_2.11-jars/livy-repl_*.jar #{node['livy']['base_dir']}/repl_2.11-jars/livy-repl.jar
        EOH
end

directory "#{node['livy']['home']}/logs" do
  owner node['livy']['user']
  group node['livy']['group']
  mode "750"
  action :create
  not_if { File.directory?("#{node['livy']['home']}/logs") }
end
