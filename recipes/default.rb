
my_ip = my_private_ip()
nn_endpoint = private_recipe_ip("hops", "nn") + ":#{node.hops.nn.port}"
home = node.hops.hdfs.user_home


livy_dir="#{home}/#{node.livy.user}/livy"
hops_hdfs_directory "#{livy_dir}" do
  action :create_as_superuser
  owner node.livy.user
  group node.hops.group
  mode "1770"
end

tmp_dirs   = [ livy_dir, "#{livy_dir}/rsc-jars", "#{livy_dir}/rpl-jars" ] 
for d in tmp_dirs
 hops_hdfs_directory d do
    action :create
    owner node.livy.user
    group node.hops.group
    mode "1777"
  end
end

file "#{node.livy.base_dir}/conf/livy.conf" do
 action :delete
end

template "#{node.livy.base_dir}/conf/livy.conf" do
  source "livy.conf.erb"
  owner node.livy.user
  group node.livy.group
  mode 0655
  variables({ 
        :private_ip => my_ip,
        :nn_endpoint => nn_endpoint
           })
end


file "#{node.livy.base_dir}/conf/spark-blacklist.conf" do
 action :delete
end

template "#{node.livy.base_dir}/conf/spark-blacklist.conf" do
  source "spark-blacklist.conf.erb"
  owner node.livy.user
  group node.livy.group
  mode 0655
end

file "#{node.livy.base_dir}/conf/livy-env.sh.erb" do
 action :delete
end

template "#{node.livy.base_dir}/conf/livy-env.sh" do
  source "livy-env.sh.erb"
  owner node.livy.user
  group node.livy.group
  mode 0655
end

template "#{node.livy.base_dir}/bin/start-livy.sh" do
  source "start-livy.sh.erb"
  owner node.livy.user
  group node.livy.group
  mode 0751
end

template "#{node.livy.base_dir}/bin/stop-livy.sh" do
  source "stop-livy.sh.erb"
  owner node.livy.user
  group node.livy.group
  mode 0751
end



case node.platform
when "ubuntu"
 if node.platform_version.to_f <= 14.04
   node.override.livy.systemd = "false"
 end
end


service_name="livy"

if node.livy.systemd == "true"

  service service_name do
    provider Chef::Provider::Service::Systemd
    supports :restart => true, :stop => true, :start => true, :status => true
    action :nothing
  end

  case node.platform_family
  when "rhel"
    systemd_script = "/usr/lib/systemd/system/#{service_name}.service" 
  else
    systemd_script = "/lib/systemd/system/#{service_name}.service"
  end

  template systemd_script do
    source "#{service_name}.service.erb"
    owner "root"
    group "root"
    mode 0754
if node.services.enabled == "true"
    notifies :enable, resources(:service => service_name)
end
    notifies :start, resources(:service => service_name), :immediately
  end

  kagent_config "reload_#{service_name}" do
    action :systemd_reload
  end  

else #sysv

  service service_name do
    provider Chef::Provider::Service::Init::Debian
    supports :restart => true, :stop => true, :start => true, :status => true
    action :nothing
  end

  template "/etc/init.d/#{service_name}" do
    source "#{service_name}.erb"
    owner "root"
    group "root"
    mode 0754
if node.services.enabled == "true"
    notifies :enable, resources(:service => service_name)
end
    notifies :start, resources(:service => service_name), :immediately
  end

end


if node.kagent.enabled == "true" 
   kagent_config service_name do
     service service_name
     log_file node.livy.log
   end
end


livy_restart "restart-livy-needed" do
  action :restart
end




bash "jupyter-hdfscontents" do
    user "root"
    code <<-EOF
    set -e
    export HADOOP_HOME=#{node[:hops][:base_dir]}
    pip install pydoop
    pip install 'hdfscontents>=0.4'
EOF
end
