require 'aws-sdk-ec2'
require 'aws-sdk-s3'

require_relative 'aws/scenario'

module EDURange
  module AWS
    def self.foo(config)
      ec2 = Aws::EC2::Resource.new
      s3 = Aws::S3::Resource.new(region: ENV['AWS_REGION'])
      Scenario.new(ec2, s3, config)
    end
  end
end

