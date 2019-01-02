require 'docker'

module EDURange
  module Docker

    require_relative 'docker/scenario'
    require_relative 'docker/cloud'
    require_relative 'docker/subnet'
    require_relative 'docker/instance'
    require_relative 'docker/dockerfile'

    def Docker.wrap(scenario_config)
      # docker library library provides global methods and is configured from ENV variables.
      Scenario.new(scenario_config)
    end
  end
end
