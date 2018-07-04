require 'active_support/core_ext/object/blank'
require_relative 'inspect'

class User
  include Inspect

  attr_reader :group, :login, :password

  LOGIN_KEY = 'Login'
  PASSWORD_KEY = 'Password'

  LOGIN_MAX_LENGTH = 32

  def initialize group, hash
    @group = group
    @login = hash[LOGIN_KEY]
    puts hash
    raise "User #{LOGIN_KEY} must not be empty" if @login.blank?
    raise "#{self.class.name} #{LONGIN_KEY} '#{@login}' contains invalid characters" unless @login.match /\A[a-zA-z_\-]*\z/
    raise "#{self.class.name} #{LONGIN_KEY} '#{@login}' is more than #{LOGIN_MAX_LENGTH} characters long" if @login.length > LOGIN_MAX_LENGTH
    @password = hash[PASSWORD_KEY]
  end

  def to_s
    "#{login}:#{password}"
  end

  def to_hash
    {
      LOGIN_KEY => login,
      PASSWORD_KEY => password
    }
  end

end

