require 'chef/resource'

class Chef::Resource::MinotaurReporter < Chef::Resource
  def initialize(name, run_context=nil)
    super
    @resource_name = :minotaur_reporter
    @provider = Chef::Provider::MinotaurReporter
    @action = :create
    @allowed_actions = [:create, :restart, :updated_by_last_action]
  end

  def name(arg=nil)
    set_or_return(:name, arg, kind_of: String, required: true)
  end

  def redis_uri(arg=nil)
    set_or_return(:redis_uri, arg, kind_of: String, required: true)
  end

  def circonus_trap_url(arg=nil)
    set_or_return(:circonus_trap_url, arg, kind_of: String, required: true)
  end

  def interval(arg=nil)
    set_or_return(:interval, arg, kind_of: Integer, default: 60)
  end

  def environment(arg=nil)
    set_or_return(:environment, arg, kind_of: Hash, default: {})
  end
end
