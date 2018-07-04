require 'erubis'

class Recipe

  attr_accessor :name, :scenario

  def initialize scenario, name
    self.scenario = scenario
    self.name = name
  end

  def text
    return path.read
  end

  def text_for instance
    return template.result(instance: instance) if template?
    return text
  end

  private

  def name= name
    raise "Recipe name '#{name}' must only contain alphanumeric characters and underscores" if /\W/.match name
    # recipes either are in current scenario's recipe directory or global recipes directory
    # TODO: I'm uncomfortable with these classes needing to know about the filesystem.
    #       They should be interacting with some recipe 'repostory' interface, so that recipes
    #       can be stored elsewhere (e.g. database, url, etc).
    # TODO: additionally, changing behavior of the class with if statements based on some condition
    #       implies that the behavior should be split between two classes.
    custom = Recipe.custom_path scenario, name
    global = Recipe.global_path scenario, name 
    raise "Recipe '#{name}' does not exist" unless custom.exist? or global.exist?
    @name = name
  end

  def path
    return custom_path if custom_path.exist?
    return global_path if global_path.exist?
    raise "Recipe '#{name}' can not be located!"
  end

  def template
    Erubis::Eruby.new(text)
  end

  def template?
    path.extname.end_with? 'erb'
  end

  def Recipe.custom_path scenario, name
    scenario.directory + 'recipes' + "#{name}.rb"
  end

  def custom_path
    Recipe.custom_path scenario, name
  end

  def Recipe.global_path scenario, name
    scenario.directory + '..' + '..' + 'recipes' + "#{name}.rb.erb"
  end

  def global_path
    Recipe.global_path scenario, name
  end

end

