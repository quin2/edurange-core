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
        @subnet = nil
      end

      delegate [:name, :cidr_block, :internet_accessible?] => :@config

      def instances
        @instances ||= @config.instances.map do |instance_config|
          EDURange::AWS::Instance.new(@ec2, @s3, instance_config)
        end
      end

      def started?
        not @subnet.nil?
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

        Subnet.tag_subnet(@config, @subnet)

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
        logger.info event: 'stopping_subnet'
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

        logger.info event: 'subnet_stopped'
          scenario: @config.scenario.name,
          cloud: @config.cloud.name,
          subnet: @config.name
      end

      def Subnet.tag_subnet(config, subnet)
        subnet.create_tags({
          tags: [
            {key: 'Name', value: config.name},
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
    end
  end
end
