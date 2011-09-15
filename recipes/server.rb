#
# Cookbook Name:: zookeeper-ubuntu
# Recipe:: server
#
# Copyright 2011, Francesco Salbaroli
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
include_recipe "zookeeper-ubuntu"

# get environment
node_env = node.chef_environment
puts node_env

if node_env == "_default" then
   raise "Can't run on default environment"
end

node_list = search(:node, "chef_environment:#{node_env}")

# DEBUG
node_list.each_with_index do |host, idx|
   puts "Host: #{host.name} - Index: #{idx}"
end
# END DEBUG

server_hosts = node_list.map{|host| host.name}.sort

config_dir = "/etc/zookeeper/conf.#{node_env}_#{node['deployment_id']}"
data_dir = node['zookeeper']['data']['dir']
client_port = node['zookeeper']['client']['port']

myid = server_hosts.find_index(node.name)

directory data_dir do
   owner "zookeeper"
   group "zookeeper"
   mode "0755"
   action :create
end

directory config_dir do
   owner "root"
   group "root"
   mode "0755"
   action :create
end

template_variables = {
   :zookeeper_server_hosts 	=> server_hosts,
   :zookeeper_data_dir 		=> data_dir,
   :myid 			=> myid,
   :zookeeper_client_port	=> client_port
}

%w{ configuration.xsl  environment  log4j.properties zoo.cfg }.each do |templ|
   template "#{config_dir}/#{templ}" do
      source "#{templ}.erb"
      mode "0644"
      owner "root"
      group "root"
      variables(template_variables)
   end
end

template "#{config_dir}/myid" do
   source "myid.erb"
   mode "0644"
   owner "zookeeper"
   group "zookeeper"
   variables(template_variables)
end

# update-alternatives install
execute "update-alternatives" do
  command "update-alternatives --install /etc/zookeeper/conf zookeeper-conf #{config_dir} 50"
  action :run
end

# update-alternatives set
execute "update-alternatives" do
  command "update-alternatives --set zookeeper-conf #{config_dir}"
  action :run
end

package "zookeeperd"

service "zookeeper" do
#   provider Chef::Provider::Service::Upstart
   action :restart
   running true
   supports :status => true, :restart => true
end 
