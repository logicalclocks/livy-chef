group node['hops']['group'] do
  gid node['hops']['group_id']
  action :create
  not_if "getent group #{node['hops']['group']}"
  not_if { node['install']['external_users'].casecmp("true") == 0 }
end

user node['livy']['user'] do
  home node['livy']['user-home']
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

group node['kagent']['userscerts_group'] do
  action :create
  not_if "getent group #{node['kagent']['userscerts_group']}"
  not_if { node['install']['external_users'].casecmp("true") == 0 }
end

group node['kagent']['userscerts_group'] do
  action :modify
  members node['livy']['user']
  append true
  not_if { node['install']['external_users'].casecmp("true") == 0 }
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

package "unzip"

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

directory "#{node['livy']['home']}/logs" do
  owner node['livy']['user']
  group node['hops']['group']
  mode "750"
  action :create
end

directory node['livy']['state_dir'] do
  owner node['livy']['user']
  group node['hops']['group']
  mode "700"
  action :create
end
