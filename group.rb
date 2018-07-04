require_relative 'access'
require_relative 'user'
require_relative 'inpsect'

class Group
  include Inspect

  attr_accessor :scenario, :instructions, :access
  attr_reader :name, :users

  NAME_KEY = 'Name'
  INSTRUCTIONS_KEY = 'Instructions'
  ACCESS_KEY = 'Access'
  USERS_KEY = 'Users'

  #def initialize(scenario:, name:, instructions: nil )
  #  self.scenario = scenario
  #  self.name = name
  #  self.instructions = instructions
  #  # self.access = access
  #end

  def initialize(scenario, hash)
    self.scenario = scenario
    self.name = hash[NAME_KEY]
    self.instructions = hash[INSTRUCTIONS_KEY]
    access_hashes = hash[ACCESS_KEY] || []
    self.access = access_hashes.map{ |access_hash| Access.new self, access_hash }
    user_hashes = hash[USERS_KEY] || []
    @users = user_hashes.map{ |user_hash| User.new self, user_hash }
  end

  def self.from_hash scenario, hash
    Group.new scenario, hash
    #group = Group.new(
    #  scenario: scenario,
    #  name: hash[NAME_KEY],
    #  instructions: hash[INSTRUCTIONS_KEY]
    #)

    # scenario.instances.find{|instance| instance.name == 
    #group
  end

  def to_hash
    {
      NAME_KEY => name,
      INSTRUCTIONS_KEY => instructions,
      ACCESS_KEY => access.map{ |a| a.to_hash }
      USERS_KEY => users.map{ |a| a.to_hash }
    }
  end

  def ip_visible_for? instance
    access.find{ |a| a.instance == instance and a.ip_visible? }.nil?
  end

  def administrator_of? instance
    access.find{ |a| a.instance == instance and a.administrator? }.nil?
  end

  def name= name
    raise "Group #{NAME_KEY} '#{name}' does not only contain alphanumeric characters and underscores`" if /\W/.match name
    @name = name
  end

  def access= access
    @access = access
  end

end

