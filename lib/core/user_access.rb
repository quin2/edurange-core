require 'forwardable'

class UserAccess
  extend Forwardable

  def initialize user, access
    @user = user
    @access = access
  end

  delegate [:login, :password, :password_hash, :group, :variables] => :@user
  delegate [:ip_visible?, :administrator?, :instance] => :@access

  def to_h
    {
      'User' => @user.to_h,
      'Access' => @access.to_h
    }
  end

  def to_s
    to_h.to_yaml
  end

  def inspect
    to_s
  end

end

