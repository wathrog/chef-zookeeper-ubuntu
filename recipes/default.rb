#
# Cookbook Name:: zookeeper-ubuntu
# Recipe:: default
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
include_recipe "apt"

# install pre-requisites
package "default-jre"

# install zookeeper
package "zookeeper"

if node['zookeeper']['environment']['name'].nil? || node['zookeeper']['environment']['name'].empty? then
   log "Environment variable NOT SET, defaulting to current node environment" 
   zookeeper_chef_environment = node.chef_environment
else
   zookeeper_chef_environment = node['zookeeper']['environment']['name']
end

puts "Environment: #{zookeeper_chef_environment}"

if zookeeper_chef_environment == "_default" then
   raise "Can't run on default environment"
end

node_list = search(:node, "chef_environment:#{zookeeper_chef_environment}")

if node_list.empty? then
   raise "No nodes matching the search pattern!"
end

# DEBUG
node_list.each_with_index do |host, idx|
   puts "Host: #{host.name} - Index: #{idx}"
end
# END DEBUG

server_hosts = node_list.map{|host| host.name}.sort

node.set['zookeeper']['server']['hosts'] = server_hosts

config_dir = "/etc/zookeeper/conf.#{zookeeper_chef_environment}_#{node['deployment_id']}"
node.set['zookeeper']['config']['dir'] = config_dir
client_port = node['zookeeper']['client']['port']
data_dir = node['zookeeper']['data']['dir']

directory config_dir do
   owner "root"
   group "root"
   mode "0755"
   action :create
end

template_variables = {
   :zookeeper_server_hosts      => server_hosts,
   :zookeeper_data_dir          => data_dir,
   :zookeeper_client_port       => client_port
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
