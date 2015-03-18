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

  def load
    return self unless checksum_exists?
    from_hash(Marshal.load(::File.read(checksum_file)))
    self
  end

  def save
    ::FileUtils.mkdir_p(Chef::Config.checksum_path)
    ::File.open(checksum_file, 'w') do |f|
      f.write Marshal.dump(to_hash)
    end
  end

  def changed?(current_resource)
    self != current_resource
  end

  def ==(o)
    to_hash == o.to_hash
  end

  def to_hash
    {name: name, redis_uri: redis_uri, table_name: table_name, environment: environment}
  end

  private
  
  def from_hash(hash)
    name(hash[:name])
    redis_uri(hash[:redis_uri])
    table_name(hash[:table_name])
    environment(hash[:environment])
  end

  def checksum_file
    '%s/minotaur-monitor--%s' % [Chef::Config.checksum_path, name]
  end

  def checksum_exists?
    ::File.exists?(checksum_file)
  end
end
