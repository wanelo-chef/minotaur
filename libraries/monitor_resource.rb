require 'chef/resource'

class Chef::Resource::MinotaurMonitor < Chef::Resource
  def initialize(name, run_context=nil)
    super
    @resource_name = :minotaur_monitor
    @provider = Chef::Provider::MinotaurMonitor
    @action = :create
    @allowed_actions = [:create, :restart, :updated_by_last_action]
  end

  def name(arg=nil)
    set_or_return(:name, arg, kind_of: String, required: true)
  end

  def redis_uri(arg=nil)
    set_or_return(:redis_uri, arg, kind_of: String, required: true)
  end

  def table_name(arg=nil)
    set_or_return(:table_name, arg, kind_of: String, required: true)
  end

  def environment(arg=nil)
    set_or_return(:environment, arg, kind_of: Hash, default: {})
  end
end
