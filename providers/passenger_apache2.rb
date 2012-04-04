#
# Cookbook Name:: application
# Provider:: passenger_apache2
#
# Copyright 2011, ZephirWorks
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

action :create do
  app = new_resource.application

  run_context.include_recipe "apache2"
  run_context.include_recipe "apache2::mod_ssl"
  run_context.include_recipe "apache2::mod_rewrite"
  run_context.include_recipe "passenger_apache2::mod_rails"

  server_aliases = [ "#{app['id']}.#{node['domain']}", node['fqdn'] ]

  if node.has_key?("cloud")
    server_aliases << node['cloud']['public_hostname']
  end

  web_app app['id'] do
    docroot "#{app['deploy_to']}/current/public"
    template "#{app['id']}.conf.erb"
    cookbook "#{app['id']}"
    server_name "#{app['id']}.#{node[:domain]}"
    server_aliases server_aliases
    log_dir node[:apache][:log_dir]
    rails_env node.chef_environment
  end

  if ::File.exists?(::File.join(app['deploy_to'], "current"))
    d = run_context.resource_collection.resources(:deploy_revision => app['id'])
    d.restart_command do
      service "apache2" do action :restart; end
    end
  end

  apache_site "000-default" do
    enable false
  end
end
