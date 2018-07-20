require 'forwardable'

class UserAccess
  extend Forwardable

  def initialize user, access
    @user = user
    @access = access
  end

  delegate [:login, :password, :password_hash, :group] => :@user
  delegate [:ip_visible?, :administrator?, :instance] => :@access

end

