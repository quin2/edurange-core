require_relative 'cloud'
require 'semantic_logger'

module EDURange::Docker
  class Scenario
    # TODO: is logging a separate concern?
    # Should logging be a delegate class that wraps calls to the underlying class with traces?
    include SemanticLogger::Loggable

    def initialize(scenario_config)
      @scenario_config = scenario_config
    end

    # TODO: There is a lot of shared code between AWS::Scenario and Docker::Scenario that is
    # likely common to all providers. Refactor the shared, provider agnostic code out.
    def clouds
      @clouds ||= @scenario_config.clouds.map do |cloud_config|
        EDURange::Docker::Cloud.new(cloud_config)
      end
    end

    def name
      @scenario_config.name
    end

    def instances
      clouds.flat_map{ |cloud| cloud.instances }
    end

    def variables
      @scenario_config.variables
    end

    def started?
      clouds.all? { |cloud| cloud.started? }
    end

    def start
      clouds.each{ |cloud| cloud.start }
    end

    def stop
      clouds.each{ |cloud| cloud.stop }
    end

  end
end

