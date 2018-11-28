require 'mustache'

class EDURange::Docker::Dockerfile < Mustache
  self.template_file = __dir__ + '/' + 'Dockerfile.mustache'

  def initialize(instance)
    @instance = instance
  end

  attr_reader :instance

end

