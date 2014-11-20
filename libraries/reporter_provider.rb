require 'chef/provider'

class Chef::Provider::MinotaurReporter < Chef::Provider
  def load_current_resource
    @current_resource ||= Chef::Resource::MinotaurReporter.new(new_resource.name)
  end

  def action_create
    helper = minotaur_helper

    git helper.directory do
      repository helper.repo
      revision helper.ref
      action :sync
      notifies :run, 'execute[bundle exec shard minotaur]'
    end

    execute 'bundle exec shard minotaur' do
      command 'bundle install --gemfile %s --deployment --without development test --path %s' % helper.bundle_args
      environment new_resource.environment
      action :nothing
      notifies :updated_by_last_action, 'minotaur_reporter[%s]' % new_resource.name, :immediately
    end

    smf new_resource.name do
      start_command 'bundle exec bin/reporter --redis %{config/redis_uri} --circonus %{config/circonus} --poll-interval %{config/interval} &'
      working_directory helper.directory

      property_groups 'config' => {
        'redis_uri' => new_resource.redis_uri,
        'circonus' => new_resource.circonus_trap_url,
        'interval' => new_resource.interval
      }

      environment({
        'LANG' => 'en_us.UTF-8',
        'LC_LANG' => 'en_us.UTF-8',
        'BUNDLE_GEMFILE' => helper.gemfile
      }.merge(new_resource.environment))

      notifies :updated_by_last_action, 'minotaur_reporter[%s]' % new_resource.name, :immediately
    end
  end

  def action_restart
    new_resource.notifies_immediately(:restart, minotaur_service)
    new_resource.updated_by_last_action(true)
  end

  def action_updated_by_last_action
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

end
