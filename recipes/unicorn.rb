#
# Cookbook Name:: application
# Recipe:: unicorn 
#
# Copyright 2009, Opscode, Inc.
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

app = node.run_state[:current_app] 

include_recipe "unicorn"

node.default[:unicorn][:worker_timeout] = 60
node.default[:unicorn][:preload_app] = false
node.default[:unicorn][:worker_processes] = [node[:cpu][:total].to_i * 4, 8].min
node.default[:unicorn][:preload_app] = false
node.default[:unicorn][:before_fork] = 'sleep 1' 
node.default[:unicorn][:after_fork] = nil 
node.default[:unicorn][:port] = '8080'
node.set[:unicorn][:options] = { :tcp_nodelay => true, :backlog => 100 }

unicorn_config "/etc/unicorn/#{app['id']}.rb" do
  listen({ node[:unicorn][:port] => node[:unicorn][:options] })
  working_directory ::File.join(app['deploy_to'], 'current')
  worker_timeout node[:unicorn][:worker_timeout] 
  preload_app node[:unicorn][:preload_app] 
  worker_processes node[:unicorn][:worker_processes]
  before_fork node[:unicorn][:before_fork] 
  after_fork node[:unicorn][:after_fork] 
  pid "/srv/#{app['id']}/shared/pids/unicorn.pid"
  owner app['owner']
  group app['group']
end

env_vars = []
log "Getting env vars for #{node.chef_environment}"
unless app['env_vars'].nil? or app['env_vars'][node.chef_environment].nil?
  env_vars = app['env_vars'][node.chef_environment]
end

runit_service app['id'] do
  template_name 'unicorn'
  cookbook 'application'
  options(
    :app => app,
    :rails_env => node.run_state[:rails_env] || node.chef_environment,
    :smells_like_rack => ::File.exists?(::File.join(app['deploy_to'], "current", "config.ru"))
  )
  env env_vars
  run_restart false
end

if ::File.exists?(::File.join(app['deploy_to'], "current")) and !(node.run_list.roles.include? "vagrant")
  d = resources(:deploy => app['id'])
  d.restart_command do
    execute "/etc/init.d/#{app['id']} hup"
  end
end

