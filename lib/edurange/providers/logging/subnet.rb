module EDURange
  module Logging
    module Subnet

      def start
        logger.info event: 'starting_subnet', **context
        super
        logger.info event: 'subnet_started', **context
      end

      def stop
        logger.info event: 'stopping_sub', **context
        super
        logger.info event: 'subnet_stopped', **context
      end

      def context
        {
          scenario: scenario.name,
          cloud: cloud.name,
          subnet: name,
        }
      end

    end
  end
end

