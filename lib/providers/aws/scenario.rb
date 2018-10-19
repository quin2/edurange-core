
require 'core/scenario'
require 'forwardable'
require_relative 'cloud'

module EDURange
  module AWS
    class Scenario
      extend Forwardable

      def initialize(ec2, s3, scenario)
        @ec2 = ec2
        @s3 = s3
        @config = scenario
      end

      delegate [:name, :description, :roles, :groups] => :@config

      def clouds
        @clouds ||= @config.clouds.map{ |cloud| EDURange::AWS::Cloud.new(@ec2, @s3, cloud) }
      end

      def start
        clouds.each{ |cloud| cloud.start }
      end

      def stop
        clouds.each{ |cloud| cloud.stop }
      end

    end
  end
end

