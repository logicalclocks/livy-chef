group node['hops']['group'] do
  gid node['hops']['group_id']
  action :create
  not_if "getent group #{node['hops']['group']}"
  not_if { node['install']['external_users'].casecmp("true") == 0 }
end

user node['livy']['user'] do
  home node['livy']['user-home']
  uid node['livy']['user_id']
  gid node['hops']['group']
  action :create
  shell "/bin/bash"
  manage_home true
  not_if "getent passwd #{node['livy']['user']}"
  not_if { node['install']['external_users'].casecmp("true") == 0 }
end

group node['hops']['group'] do
  action :modify
  members ["#{node['livy']['user']}"]
  append true
  not_if { node['install']['external_users'].casecmp("true") == 0 }
end

group node["kagent"]["certs_group"] do
  action :manage
  append true
  excluded_members node['livy']['user']
  not_if { node['install']['external_users'].casecmp("true") == 0 }
  only_if { conda_helpers.is_upgrade }
end

group node['hops']['group'] do
  action :modify
  members node['livy']['user']
  append true
  not_if { node['install']['external_users'].casecmp("true") == 0 }
end

directory node["livy"]["dir"] do
  owner node["livy"]["user"]
  group node["livy"]["group"]
  mode "755"
  action :create
  not_if { File.directory?("#{node["livy"]["dir"]}") }
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

package "unzip" do
  retries 10
  retry_delay 30
end

# Extract Livy
livy_downloaded = "#{node['livy']['home']}/.livy_extracted_#{node['livy']['version']}"

bash 'extract-livy' do
  user "root"
  group node['hops']['group']
  code <<-EOH
    set -e
    unzip #{cached_package_filename} -d #{Chef::Config['file_cache_path']}
    mv #{Chef::Config['file_cache_path']}/apache-livy-#{node['livy']['version']} #{node['livy']['dir']}

    # remove old symbolic link, if any
    rm -f #{node['livy']['base_dir']}

    ln -s #{node['livy']['home']} #{node['livy']['base_dir']}
    touch #{livy_downloaded}
    chmod 750 #{node['livy']['home']}
    chown -R #{node['livy']['user']}:#{node['hops']['group']} #{node['livy']['home']}
    chown -R #{node['livy']['user']}:#{node['hops']['group']} #{node['livy']['base_dir']}
  EOH
  not_if { ::File.exists?( "#{livy_downloaded}" ) }
end

directory node['data']['dir'] do
  owner 'root'
  group 'root'
  mode '0775'
  action :create
  not_if { ::File.directory?(node['data']['dir']) }
end

directory node['livy']['data_volume']['root_dir'] do
  owner node['livy']['user']
  group node['hops']['group']
  mode '0750'
end

directory node['livy']['data_volume']['logs_dir'] do
  owner node['livy']['user']
  group node['hops']['group']
  mode '0750'
end

bash 'Move Livy logs to data volume' do
  user 'root'
  code <<-EOH
    set -e
    mv -f #{node['livy']['logs_dir']}/* #{node['livy']['data_volume']['logs_dir']}
    rm -rf #{node['livy']['logs_dir']}
  EOH
  only_if { conda_helpers.is_upgrade }
  only_if { File.directory?(node['livy']['logs_dir'])}
  not_if { File.symlink?(node['livy']['logs_dir'])}
end

link node['livy']['logs_dir'] do
  owner node['livy']['user']
  group node['hops']['group']
  mode '0750'
  to node['livy']['data_volume']['logs_dir']
end

directory node['livy']['data_volume']['state_dir'] do
  owner node['livy']['user']
  group node['hops']['group']
  mode '0700'
end

bash 'Move Livy state to data volume' do
  user 'root'
  code <<-EOH
    set -e
    mv -f #{node['livy']['state_dir']}/* #{node['livy']['data_volume']['state_dir']}
  EOH
  only_if { conda_helpers.is_upgrade }
  only_if { File.directory?(node['livy']['state_dir'])}
  not_if { File.symlink?(node['livy']['state_dir'])}
  not_if { Dir.empty?(node['livy']['state_dir'])}
end

bash 'Delete old Livy state' do
  user 'root'
  code <<-EOH
    set -e
    rm -rf #{node['livy']['state_dir']}
  EOH
  only_if { conda_helpers.is_upgrade }
  only_if { File.directory?(node['livy']['state_dir'])}
  not_if { File.symlink?(node['livy']['state_dir'])}
end

link node['livy']['state_dir'] do
  owner node['livy']['user']
  group node['hops']['group']
  mode '0700'
  to node['livy']['data_volume']['state_dir']
end
