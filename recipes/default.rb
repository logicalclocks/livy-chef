kagent_hopsify "Generate x.509" do
  user node['livy']['user']
  crypto_directory x509_helper.get_crypto_dir(node['livy']['user'])
  action :generate_x509
  not_if { node["kagent"]["test"] == true }
end

rsc_jars = ""
repl_jars = ""
datanucleus_jars = ""
pyspark_archives = ""
ruby_block 'read dir content for configuration' do
  block do
    rsc_jars = Dir["#{node['livy']['base_dir']}/rsc-jars/*"]
        .map{|d| "local://#{d}"}
        .join(",")
    repl_jars = Dir["#{node['livy']['base_dir']}/repl_#{node['scala']['version']}-jars/*"]
        .map{|d| "local://#{d}"}
        .join(",")
    datanucleus_jars= Dir["#{node['hadoop_spark']['base_dir']}/jars/*"]
        .select{|d| d.include?("datanucleus")}
        .map{|d| "local://#{d}"}
        .join(",")
    pyspark_archives = Dir["#{node['hadoop_spark']['base_dir']}/python/lib/*"]
        .select{|d| d.include?(".zip")}
        .map{|d| "local://#{d}"}
        .join(",")
  end
end

template "#{node['livy']['base_dir']}/conf/livy.conf" do
  source "livy.conf.erb"
  owner node['livy']['user']
  group node['hops']['group']
  mode 0655
  variables( lazy {{
      :rsc_jars => rsc_jars,
      :repl_jars => repl_jars,
      :datanucleus_jars => datanucleus_jars,
      :pyspark_archives => pyspark_archives
  }})
end

livy_fqdn = consul_helper.get_service_fqdn("livy")
template "#{node['livy']['base_dir']}/conf/livy-client.conf" do
  source "livy-client.conf.erb"
  owner node['livy']['user']
  group node['hops']['group']
  mode 0655
  variables({
    :livy_fqdn => livy_fqdn,
  })
end

template "#{node['livy']['base_dir']}/conf/log4j.properties" do
  source "log4j.properties.erb"
  owner node['livy']['user']
  group node['hops']['group']
  mode 0655
end


template "#{node['livy']['base_dir']}/conf/spark-blacklist.conf" do
  source "spark-blacklist.conf.erb"
  owner node['livy']['user']
  group node['hops']['group']
  mode 0655
end

template "#{node['livy']['base_dir']}/conf/livy-env.sh" do
  source "livy-env.sh.erb"
  owner node['livy']['user']
  group node['hops']['group']
  mode 0655
end

rpc_resourcemanager_fqdn = consul_helper.get_service_fqdn("rpc.resourcemanager")
template "#{node['livy']['base_dir']}/bin/start-livy.sh" do
  source "start-livy.sh.erb"
  owner node['livy']['user']
  group node['hops']['group']
  mode 0751
  variables({
       :rm_rpc_endpoint => rpc_resourcemanager_fqdn
  })
end

template "#{node['livy']['base_dir']}/bin/stop-livy.sh" do
  source "stop-livy.sh.erb"
  owner node['livy']['user']
  group node['hops']['group']
  mode 0751
end

template "#{node['livy']['base_dir']}/bin/livy-health.sh" do
  source "livy-health.sh.erb"
  owner node['livy']['user']
  group node['livy']['group']
  mode 0555
end

service_name="livy"

service service_name do
  provider Chef::Provider::Service::Systemd
  supports :restart => true, :stop => true, :start => true, :status => true
  action :nothing
end

case node['platform_family']
when "rhel"
  systemd_script = "/usr/lib/systemd/system/#{service_name}.service"
else
  systemd_script = "/lib/systemd/system/#{service_name}.service"
end

deps = ""
if exists_local("hops", "rm")
  deps += "resourcemanager.service "
end
deps += "consul.service "

template systemd_script do
  source "#{service_name}.service.erb"
  owner "root"
  group "root"
  mode 0754
  variables({
      :deps => deps,
      :rm_rpc_endpoint => rpc_resourcemanager_fqdn
  })
if node['services']['enabled'] == "true"
    notifies :enable, resources(:service => service_name)
end
    notifies :start, resources(:service => service_name), :immediately
end

kagent_config service_name do
  action :systemd_reload
end

if node['kagent']['enabled'] == "true"
   kagent_config service_name do
     service service_name
     log_file node['livy']['log']
   end
end

consul_service "Registering Livy with Consul" do
  service_definition "livy-consul.hcl.erb"
  action :register
end
