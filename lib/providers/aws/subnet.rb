require 'forwardable'
require_relative 'instance'
require 'logging'
require 'date'

module EDURange
  module AWS
    class Subnet
      include SemanticLogger::Loggable
      extend Forwardable

      def initialize(subnet_config)
        @config = subnet_config
      end

      delegate [:name, :cidr_block, :internet_accessible?] => :@config

      def instances
        @instances ||= @config.instances.map{ |instance| EDURange::AWS::Instance.new(instance) }
      end

      def started?
        not @subnet.nil?
      end

      def start(ec2, vpc, gateway)
        logger.trace 'starting subnet', scenario: @config.scenario.name, cloud: @config.cloud.name, subnet: @config.name
        #raise "Must start cloud before starting subnet." unless vpc
        raise "Subnet #{name} already started" if started?

        @subnet = vpc.create_subnet({
          cidr_block: cidr_block.to_string
        })

        Subnet.tag_subnet(@config, @subnet)

        route_table = vpc.create_route_table
        route_table.create_tags({
          tags: [
            {key: 'ScenarioName', value: name }
          ]
        })

        route_table.associate_with_subnet(subnet_id: @subnet.id)

        if internet_accessible? then
          route_table.create_route({
            destination_cidr_block: '0.0.0.0/0',
            gateway_id: gateway.id
          })
        end

        instances.each do |instance|
          instance.start(ec2, @subnet)
        end
        logger.trace 'started subnet', scenario: @config.scenario.name, cloud: @config.cloud.name, subnet: @config.name
      end

      def stop
        instances.each do |instance|
          instance.stop
        end

        # deleting the route table here could be iffy if we use the default route table.
        route_table = Subnet.route_table(@subnet)
        if route_table then
          route_table.associations.each { |association| association.delete }
          route_table.delete
        end

        @subnet.delete
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

      def Subnet.route_table(subnet)
        subnet.vpc.route_tables({
          filters: [
            {
              name: 'association.subnet-id',
              values: [subnet.id],
            }
          ]
        }).first
      end

    end
  end
end


