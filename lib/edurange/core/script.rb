# TODO: literally just copied then modiefied from recipes. obviously they are doing similar things. DRY it.
require 'mustache'

class Script

  attr_reader :name

  def initialize(path, name)
    raise "Script file '#{path}' does not exist" unless path.file?
    @path = path
    raise "Script name must not be epty" if name.blank?
    raise "Script name '#{name}' must only contain alphanumeric characters and underscores" if /\W/.match name
    @name = name
  end

  def contents
    return @path.read
  end

  def contents_for instance
    if template?
      Mustache.raise_on_context_miss = true #TODO: shouldn't be messing with global settings here
      return Mustache.render(contents, instance)
    else
      return contents
    end
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
  def Script.for_scenario scenario, name
    # TODO: pile of crap!
    possible_locations = [
      scenario.directory + 'scripts' + "#{name}.sh.mustache",
      scenario.directory + 'scripts' + "#{name}.sh",
      scenario.directory + '..' + '..' + 'scripts' + "#{name}.sh.mustache",
      scenario.directory + '..' + '..' + 'scripts' + "#{name}.sh",
    ]

    actual_locations = possible_locations.select{|path| path.file?}

    if actual_locations.empty? then
      raise "Script '#{name}' not located at any of: #{possible_locations.join(', ')}"
    else
      Script.new(actual_locations.first, name)
    end
  end

  private

  def template?
    @path.extname.end_with? 'mustache'
  end

end

