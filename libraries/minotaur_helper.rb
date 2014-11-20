class MinotaurHelper < Struct.new(:node)
  def directory
    node['minotaur']['install']['dir']
  end

  def repo
    node['minotaur']['install']['repo']
  end

  def ref
    node['minotaur']['install']['ref']
  end

  def bundle_args
    [gemfile, bundle_directory]
  end

  def bundle_directory
    '%s/.bundle' % directory
  end

  def gemfile
    '%s/Gemfile' % directory
  end
end
