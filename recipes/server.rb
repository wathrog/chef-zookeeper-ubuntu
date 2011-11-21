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

server_hosts = node.set['zookeeper']['server']['hosts']

myid = server_hosts.find_index(node.name)

if myid.nil? then
   raise "Can't find ME node in node list! Impossible to install a zookeeper server!"
end

data_dir = node['zookeeper']['data']['dir']
config_dir = node['zookeeper']['config']['dir']

directory data_dir do
   owner "zookeeper"
   group "zookeeper"
   mode "0755"
   action :create
end

template "#{config_dir}/myid" do
   source "myid.erb"
   mode "0644"
   owner "zookeeper"
   group "zookeeper"
   variables({:myid => myid})
end

package "zookeeperd"

service "zookeeper" do
#   provider Chef::Provider::Service::Upstart
   action :restart
   running true
   supports :status => true, :restart => true
end 
