#
# Cookbook Name:: application
# Recipe:: default
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

include_recipe 'runit'

search(:apps) do |app|
  (app["server_roles"] & node.roles).each do |app_role|
    unless app["type"][app_role]
      Chef::Log.warn("Nothing to do for #{app_role}, check app[:type]")
      next
    end

    app["type"][app_role].each do |thing|
      send(:"application_#{thing}", app[:id]) do
        application app
        action :create
      end
    end
  end
end
