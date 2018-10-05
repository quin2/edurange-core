require 'forwardable'

class UserAccess
  extend Forwardable

  def initialize user, access
    @user = user
    @access = access
  end

  delegate [:login, :password, :password_hash, :group] => :@user
  delegate [:ip_visible?, :administrator?, :instance] => :@access

  def to_hash
    {
      'User' => @user.to_hash,
      'Access' => @access.to_hash
    }
  end

  def to_s
    to_hash.to_yaml
  end

  def inspect
    to_s
  end

end

