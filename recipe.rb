require 'erubis'

class Recipe

  attr_reader :name

  def initialize path, name
    raise "Recipe file '#{path}' does not exist" unless path.file?
    @path = path
    raise "Recipe name '#{name}' must only contain alphanumeric characters and underscores" if /\W/.match name
    @name = name
  end

  def text
    return @path.read
  end

  def text_for instance
    return template.result(instance: instance) if template?
    return text
  end

  def to_s
    name
  end

  def inspect
    to_s
  end

  # recipes either are in current scenario's recipe directory or global recipes directory
  # TODO: I'm uncomfortable with these classes needing to know about the filesystem.
  #       They should be interacting with some recipe 'repostory' interface, so that recipes
  #       can be stored elsewhere (e.g. database, url, etc).
  def Recipe.for_scenario scenario, name
    custom_path = scenario.directory + 'recipes' + "#{name}.rb"
    global_path = scenario.directory + '..' + '..' + 'recipes' + "#{name}.rb.erb"
    case
    when custom_path.file?
      Recipe.new custom_path, name
    when global_path.file?
      Recipe.new global_path, name
    else
      raise "Recipe '#{name}' not located at either '#{custom}' or #{global}"
    end
  end

  private

  def template
    Erubis::Eruby.new(text)
  end

  def template?
    @path.extname.end_with? 'erb'
  end

end

