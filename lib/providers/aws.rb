require 'aws-sdk-ec2'
require_relative 'aws/scenario'

module EDURange
  module AWS
    def self.foo(config)
      ec2 = Aws::EC2::Resource.new
      Scenario.new(ec2, config)
    end
  end
end

