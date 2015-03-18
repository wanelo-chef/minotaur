require 'chef/provider'

class Chef::Provider::MinotaurMonitor < Chef::Provider
  def load_current_resource
    @current_resource ||= Chef::Resource::MinotaurMonitor.new(new_resource.name).load
  end

  def action_create
    helper = minotaur_helper

    git helper.directory do
      repository helper.repo
      revision helper.ref
      action :sync
      notifies :run, "bundle[bundle install minotaur - #{new_resource.name}]"
    end

    bundler_action = new_resource.changed?(current_resource) ? :install : :nothing
    bundle "bundle install minotaur - #{new_resource.name}" do
      user 'root'
      group 'root'
      gemfile helper.gemfile
      path helper.bundle_directory
      environment new_resource.environment
      action bundler_action
      notifies :updated_by_last_action, 'minotaur_monitor[%s]' % new_resource.name, :immediately
    end

    smf new_resource.name do
      start_command 'bundle exec bin/monitor --redis %{config/redis_uri} --table %{config/table_name} &'
      working_directory helper.directory

      property_groups 'config' => {
        'redis_uri' => new_resource.redis_uri,
        'table_name' => new_resource.table_name
      }

      environment({
        'LANG' => 'en_us.UTF-8',
        'LC_LANG' => 'en_us.UTF-8',
        'BUNDLE_GEMFILE' => helper.gemfile
      }.merge(new_resource.environment))

      notifies :updated_by_last_action, 'minotaur_monitor[%s]' % new_resource.name, :immediately
    end

    new_resource.save if changed?
  end

  def action_restart
    new_resource.notifies_immediately(:restart, minotaur_service)
    new_resource.updated_by_last_action(true)
  end

  def action_updated_by_last_action
    new_resource.save
    new_resource.updated_by_last_action(true)
  end

  private

  def minotaur_helper
    @helper ||= MinotaurHelper.new(node)
  end

  def minotaur_service
    begin
      run_context.resource_collection.find(service: new_resource.name)
    rescue Chef::Exceptions::ResourceNotFound
      service new_resource.name do
        supports restart: true, status: true, reload: true
      end
    end
  end

  def changed?
    new_resource != current_resource
  end
end
