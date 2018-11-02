require 'forwardable'
require_relative 'instance'
require 'logging'
require 'date'

module EDURange
  module AWS
    class Subnet
      include SemanticLogger::Loggable
      extend Forwardable

      def initialize(ec2, s3, subnet_config)
        @ec2 = ec2
        @s3 = s3
        @config = subnet_config
        @subnet = Subnet.preexisting_aws_subnet(ec2, self)
      end

      delegate [:name, :cidr_block, :internet_accessible?, :scenario, :cloud] => :@config

      # a globally unique identifier for this EduRange instance.
      def identifier
        # todo: needs additional identifier to differentiate between instances of scenarios.
        "edurange:#{scenario.name}/#{cloud.name}/#{name}"
      end

      def instances
        @instances ||= @config.instances.map do |instance_config|
          EDURange::AWS::Instance.new(@ec2, @s3, instance_config)
        end
      end

      def created?
        not @subnet.nil?
      end

      def started?
        created? and instances.all? do |instance|
          instance.started?
        end
      end

      def start(vpc, gateway)
        logger.info event: 'starting_subnet',
          scenario: @config.scenario.name,
          cloud: @config.cloud.name,
          subnet: @config.name

        #raise "Must start cloud before starting subnet." unless vpc
        raise "Subnet #{name} already started" if started?

        @subnet = vpc.create_subnet({
          cidr_block: cidr_block.to_string
        })

        Subnet.tag_subnet(self, @subnet)

        route_table = vpc.create_route_table
        Subnet.tag_route_table(@config, route_table)
        route_table.associate_with_subnet(subnet_id: @subnet.id)

        if internet_accessible? then
          route_table.create_route({
            destination_cidr_block: '0.0.0.0/0',
            gateway_id: gateway.id
          })
        end

        instances.each do |instance|
          instance.start(@subnet)
        end

        logger.info event: 'subnet_started',
          scenario: @config.scenario.name,
          cloud: @config.cloud.name,
          subnet: @config.name
      end

      def stop
        logger.info event: 'stopping_subnet',
          scenario: @config.scenario.name,
          cloud: @config.cloud.name,
          subnet: @config.name


        instances.each do |instance|
          instance.stop
        end

        # deleting the route table here could be iffy if we use the default route table.
        route_table = Subnet.existing_route_table_for_subnet(@subnet)
        if route_table then
          route_table.associations.each do |association|
            logger.trace 'disassociating route table from subnet',
              route_table_id: association.route_table_id,
              subnet_id: association.subnet_id

            association.delete
          end
          route_table.delete
        end

        @subnet.delete

        logger.info event: 'subnet_stopped',
          scenario: @config.scenario.name,
          cloud: @config.cloud.name,
          subnet: @config.name
      end

      def Subnet.tag_subnet(config, subnet)
        subnet.create_tags({
          tags: [
            {key: 'Name', value: config.name},
            {key: 'SubnetName', value: config.name},
            {key: 'CloudName', value: config.cloud.name},
            {key: 'ScenarioName', value: config.scenario.name},
            {key: 'DateCreated', value: DateTime.now.iso8601 }
          ]
        })
      end

      def Subnet.tag_route_table(config, route_table)
        route_table.create_tags({
          tags: [
            {key: 'ScenarioName', value: config.scenario.name },
            {key: 'CloudName', value: config.cloud.name },
            {key: 'SubnetName', value: config.name },
            {key: 'DateCreated', value: DateTime.now.iso8601 },
          ]
        })
      end

      def Subnet.existing_route_table_for_subnet(subnet)
        if not subnet.nil? then
          return subnet.vpc.route_tables({
            filters: [
              { name: 'association.subnet-id', values: [subnet.id] },
              { name: 'association.main', values: ['false'] }
            ]
          }).first
        else
          return nil
        end
      end

      def Subnet.preexisting_aws_subnet(ec2, config)
        s = ec2.subnets({
          filters: [
            {name: 'tag:Name', values: [config.identifier]},
          ]
        }).first
        logger.trace 'found preexisting aws subnet' if s
        return s
      end

    end
  end
end
