module EDURange
  module Logging
    module Subnet

      # TODO: is this a good idea in the first place? if it is, scenario/cloud/subnet/instance should all do it.
      def self.log method
        define_method method do
          begin
            logger.info event: "#{method.to_s}", **context
            super()
            logger.info event: "#{method.to_s}_succeeded", **context
          rescue => e
            logger.error event: "#{method.to_s}_failed", **context, reason: e.message.strip
            raise
          end
        end
      end

      [:start, :stop].each do |method|
        self.log method
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

