
module EDURange
  module Logging
    module Base
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
    end
  end
end
