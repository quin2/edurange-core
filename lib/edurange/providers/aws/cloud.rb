require 'forwardable'
require 'date'
require_relative 'subnet'

module EDURange
  module AWS
    class Cloud
      include SemanticLogger::Loggable
      extend Forwardable

      def initialize(ec2, s3, cloud_config)
        @config = cloud_config
        @s3 = s3
        @ec2 = ec2
        @vpc = Cloud.preexisting_vpc(ec2, self)
      end

      # a globally unique identifier for this EduRange instance.
      def identifier
        # todo: needs additional identifier to differentiate between instances of scenarios.
        "edurange:#{scenario.name}/#{name}"
      end

#      def Cloud.create(cloud_config)
#        ec2 = Aws::EC2::Resource.new
#        Cloud.new(ec2, cloud_config)
#      end

#      def Cloud.find(cloud_config, vpc_id)
#        ec2 = Aws::EC2::Resource.new
#        vpc = ec2.vpc(vpc_id)
#        Cloud.new(ec2, cloud_config, vpc)
#      end

      def Cloud.preexisting_vpc(ec2, config)
        c = ec2.vpcs({
          filters: [
            { name: 'tag:Name', values: [config.identifier] }
          ]
        }).first
        logger.trace 'found preexisting vpc' if c
        return c
      end

      delegate [:name, :cidr_block, :scenario] => :@config

      def subnets
        @subnets ||= @config.subnets.map do |subnet_config|
          EDURange::AWS::Subnet.new(@ec2, @s3, subnet_config)
        end
      end

      def vpc
        @vpc
      end

      def created?
        not vpc.nil? and tagged?
      end

      def started?
        created? and subnets.all? do |subnet|
          subnet.started?
        end
      end

      def tagged?
        tags.has_key?('Name')
      end

      def tags
        ts = {}
        if vpc then
          vpc.tags.each do |tag|
            ts[tag.key] = tag.value
          end
        end
        return ts
      end

      def start
        logger.info event: 'starting_cloud',
          name: @config.name,
          scenario: @config.scenario.name

        raise "Cloud #{name} already started" if started?

        @vpc = @ec2.create_vpc({ cidr_block: cidr_block.to_string })

        Cloud.tag_cloud(self, @vpc)

        # temporary
#        key_pair = @ec2.create_key_pair({
#          key_name: 'DUMMY'
#        })
#        Pathname.new("./#{key_pair.name}.pem").write(key_pair.key_material)

        gateway = Cloud.create_internet_gateway(@ec2, @vpc)

        Cloud.configure_default_security_group(@vpc)

        subnets.each do |subnet|
          subnet.start(@vpc, gateway)
        end

        logger.info event: 'cloud_started',
          name: @config.name,
          scenario: @config.scenario.name
      end

      def stop
        logger.info event: 'stopping_cloud',
          name: @config.name,
          scenario: @config.scenario.name

        subnets.each{ |subnet| subnet.stop }
        Cloud.delete_internet_gateway(@vpc)
        @vpc.delete

        logger.info event: 'cloud_stopped',
          name: @config.name,
          scenario: @config.scenario.name
      end

      def Cloud.tag_cloud(config, vpc)
        vpc.create_tags({
          tags: [
            {key: 'Name',         value: config.identifier},
            {key: 'CloudName',    value: config.name},
            {key: 'ScenarioName', value: config.scenario.name},
            {key: 'DateCreated',  value: DateTime.now.iso8601},
          ]
        })
      end

      def Cloud.create_internet_gateway(ec2, vpc)
        gateway = ec2.create_internet_gateway()
        gateway.attach_to_vpc({
          vpc_id: vpc.id
        })
        gateway
      end

      def Cloud.delete_internet_gateway(vpc)
        vpc.internet_gateways().each do |internet_gateway|
          vpc.detach_internet_gateway({
            internet_gateway_id: internet_gateway.id
          })
          internet_gateway.delete
        end
      end

      def Cloud.configure_default_security_group(vpc)
        security_group = vpc.security_groups.first
        security_group.authorize_ingress({
          ip_permissions: [{
            ip_protocol: "tcp",
            from_port: 22,
            to_port: 22,
            ip_ranges: [
              {
                cidr_ip: "0.0.0.0/0",
              }
            ]
          }]
        })
      end

    end
  end
end


