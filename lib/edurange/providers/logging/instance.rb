require 'semantic_logger'

module EDURange
  module Logging
    module Instance

      def start
        logger.info event: 'starting_instance', **context
        super
        logger.info event: 'instance_started', **context
      end

      def stop
        logger.info event: 'stopping_instance', **context
        super
        logger.info event: 'instance_stopped', **context
      end

      def context
        {
          scenario: scenario.name,
          cloud: cloud.name,
          subnet: subnet.name,
          instance: name
        }
      end

    end
  end
end

