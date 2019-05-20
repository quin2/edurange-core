require 'aws-sdk-ec2'
require 'aws-sdk-s3'

require_relative 'aws/scenario'

module EDURange
  module AWS
    def self.foo(config)
      AWS.assert_environment_variables_present
      ec2 = Aws::EC2::Resource.new
      s3 = Aws::S3::Resource.new(region: ENV['AWS_REGION'], 
        access_key_id: ENV['AWS_ACCESS_KEY_ID'], 
        secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'])
      Scenario.new(ec2, s3, config)
    end

    def AWS.wrap(scenario_config) #not DRY at all but I had to make it work... 
      AWS.assert_environment_variables_present
      ec2 = Aws::EC2::Resource.new
      s3 = Aws::S3::Resource.new(region: ENV['AWS_REGION'], 
        access_key_id: ENV['AWS_ACCESS_KEY_ID'], 
        secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'])
      Scenario.new(ec2, s3, scenario_config)
    end

    def AWS.assert_environment_variables_present
      required_variables = [
        'AWS_ACCESS_KEY_ID',
        'AWS_SECRET_ACCESS_KEY',
        'AWS_REGION'
      ]

      missing_variables = required_variables.select{|name| not ENV.include?(name)}

      if not missing_variables.empty? then
        raise 'Missing environment variable(s): ' + missing_variables.join(', ')
      end
    end

  end
end

