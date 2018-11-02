require_relative 'provider_test_base'
require 'providers/docker'
require 'core/scenario'

class DockerTest < Minitest::Test
  include ProviderTestBase
  def provider
    EDURange::Docker
  end
end

