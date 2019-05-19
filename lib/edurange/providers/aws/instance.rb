require 'base64'
require 'date'
require 'semantic_logger'
require 'logging'

module EDURange
  module AWS
    class Instance
      include SemanticLogger::Loggable
      extend Forwardable

      def initialize(ec2, s3, instance_config)
        @ec2 = ec2
        @s3 = s3
        @config = instance_config
        @instance = Instance.preexisting_aws_instance(ec2, self)
      end

      delegate [:name, :os, :ip_address, :ip_address_dynamic, :users, :administrators, :recipes, :packages, :startup_script, :cloud, :scenario, :subnet, :internet_accessible?, :roles] => :@config

      # a globally unique identifier for this EduRange instance.
      def identifier
        # todo: needs additional identifier to differentiate between instances of scenarios.
        "edurange:#{scenario.name}/#{cloud.name}/#{subnet.name}/#{self.name}"
      end

      def started?
        (not @instance.nil?) and status_s3_object.exists?
      end

      def start(subnet)
        logger.info event: 'starting_instance',
          scenario: @config.scenario.name,
          cloud: @config.cloud.name,
          subnet: @config.subnet.name,
          instance: @config.name
          #startup_script: @config.startup_script.name

        @instance = Instance.create_instance(@config, subnet, status_s3_object_put_url)

        logger.info "instance id: #{@instance.id}"

        Instance.tag_instance(self, @instance)

        @instance.wait_until_running

        Instance.assign_public_ip_address(@instance, self) if internet_accessible?

        # reload instance data
        @instance.load

        # TODO weird and hacky, this status stuff should be in it's own class not literring this one
        while not status_s3_object.exists?
          duration = 15
          logger.trace "waiting #{duration}s for status page"
          sleep(duration)
        end

        logger.info event: 'instance_started',
          scenario: @config.scenario.name,
          cloud: @config.cloud.name,
          subnet: @config.subnet.name,
          instance: @config.name
      end

      def stop
        logger.info event: 'stopping_instance',
          scenario: @config.scenario.name,
          cloud: @config.cloud.name,
          subnet: @config.subnet.name,
          instance: @config.name

        Instance.unassign_public_ip_address(@instance) if internet_accessible?

        @instance.terminate
        @instance.wait_until_terminated

        # delete s3 object
        status_s3_object.delete

        logger.info event: 'instance_stopped',
          scenario: @config.scenario.name,
          cloud: @config.cloud.name,
          subnet: @config.subnet.name,
          instance: @config.name
      end

      def public_ip_address
        IPAddress.parse @instance.public_ip_address if @instance
      end

      private

      def status_s3_object
        @status_s3_object ||= Instance.status_s3_object @s3
      end

      def status_s3_object_put_url
        status_s3_object.presigned_url(:put)
      end

      def Instance.status_s3_object s3
         bucket = s3.bucket('edurange-playground')
         bucket.create() if not bucket.exists?
         bucket.object('status') # TODO, needs to be unique identifier for this scenario/instance
      end

      # retrieves instance from subnet with correct name.
      #def Instance.fetch(config, subnet)
      #  subnet.instances({
      #    filters: [
      #      {
      #        name: 'tag:Name',
      #        values: [config.name]
      #      }
      #    ]
      #  }).first
      #end

      def Instance.create_instance(config, subnet, status_object_url)
        subnet.create_instances({
          image_id: 'ami-40184038', # TODO, just hardcoding the ami right now.
          private_ip_address: config.ip_address.to_s,
          max_count: 1,
          min_count: 1,
          instance_type: 't1.micro', # TODO, also shouldn't be hardcoded? 
          user_data: Base64.encode64(config.startup_script.gsub("{{status_object_url}}", status_object_url)), # todo use actual templates eventually.
#          key_name: key_name
        }).first
      end

      def Instance.tag_instance(config, instance)
        instance.create_tags({
          tags: [
            { key: 'Name', value: config.identifier },
            { key: 'InstanceName', value: config.name },
            { key: 'SubnetName', value: config.subnet.name },
            { key: 'CloudName', value: config.cloud.name },
            { key: 'ScenarioName', value: config.scenario.name },
            { key: 'DateCreated', value: DateTime.now.iso8601 }
          ]
        })
      end

      def Instance.assign_public_ip_address(instance, config)
        client = instance.client
        elastic_ip_allocation = client.allocate_address({
          domain: 'vpc'
        });

        # Tag the elastic ip. Great for debugging!
        # TODO: lots of duplicate tags everywhere, DRY up.
        client.create_tags({
          resources: [ elastic_ip_allocation.allocation_id ],
          tags: [
            { key: 'InstanceName', value: config.name },
            { key: 'SubnetName', value: config.subnet.name },
            { key: 'CloudName', value: config.cloud.name },
            { key: 'ScenarioName', value: config.scenario.name },
            { key: 'DateCreated', value: DateTime.now.iso8601 },
          ]
        })

        client.associate_address({
          allocation_id: elastic_ip_allocation.allocation_id,
          instance_id: instance.id
        })
        logger.trace 'public ip address assigned', instance: instance.id, ip_address: elastic_ip_allocation.public_ip
      end

      def Instance.unassign_public_ip_address(instance)
        client = instance.client

        addresses = client.describe_addresses({
          filters: [
            {
              name: 'instance-id',
              values: [instance.id]
            }
          ]
        }).addresses

        addresses.each do |address|
          logger.trace "Disassociating elastic ip #{address.public_ip} from instance #{address.instance_id}."
          client.disassociate_address({
            association_id: address.association_id
          })

          logger.trace "Releasing elastic ip #{address.public_ip}."
          client.release_address({
            allocation_id: address.allocation_id,
          })
        end
      end

      def Instance.preexisting_aws_instance(ec2, config)
        i = ec2.instances({
          filters: [
            {name: 'tag:Name', values: [config.identifier]},
            {name: 'instance-state-name', values: ['pending', 'running', 'stopping', 'stopped']},
          ]
        }).first
        logger.trace "found preexisting ec2 instance" if i
        return i
      end
    end
  end
end

