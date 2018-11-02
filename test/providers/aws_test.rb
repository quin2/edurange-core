require_relative 'provider_test_base'
require 'providers/aws'

class AWSTest < Minitest::Test
  include ProviderTestBase

  def provider
    EDURange::AWS
  end

end

