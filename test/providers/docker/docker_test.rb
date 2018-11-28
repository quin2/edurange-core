require_relative '../../test_helper'
require 'core/scenario'

require 'providers/docker/instance_image'

class DockerTest < Minitest::Test


  def test_build_image
    scenario = Scenario.load_from_yaml_file('./scenarios/test/basic/basic.yml')
#    scenario = EDURange::Docker.foo(scenario_config)
    instance = scenario.instances.first

    image = EDURange::Docker::InstanceImage.build(instance)

    image.delete
  end

end

