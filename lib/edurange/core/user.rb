require 'active_support/core_ext/object/blank'
require_relative 'inspect'
require_relative 'password'

class User
  include Inspect

  attr_reader :group, :login, :password

  LOGIN_KEY = 'Login'
  PASSWORD_KEY = 'Password'

  LOGIN_MAX_LENGTH = 32

  def initialize group, hash
    @group = group
    @login = hash[LOGIN_KEY]
    raise "User #{LOGIN_KEY} must not be empty" if @login.blank?
    raise "#{self.class.name} #{LOGIN_KEY} '#{@login}' contains invalid characters" unless @login.match (/\A[a-zA-Z_\-]*\z/)
    raise "#{self.class.name} #{LOGIN_KEY} '#{@login}' is more than #{LOGIN_MAX_LENGTH} characters long" if @login.length > LOGIN_MAX_LENGTH

    if hash[PASSWORD_KEY]
      @password = Password.new hash[PASSWORD_KEY]
    else
      @password = Password.random
    end
  end

  # user specific variables
  def variables
    # NOTE: this has potentially unexpected behavior: this is where player variables are "instantiated"
    @variables ||= OpenStruct.new(Hash[group.variables.collect { |var| [var.name, var.value] }])
  end

  def to_s
    "#{login}:#{password}"
  end

  def to_h
    {
      LOGIN_KEY => login,
      PASSWORD_KEY => password.to_s
    }
  end

#  def password_hash
#    warn 'I want to move this away from User in the future.'
#    password.hash
#  end

end

