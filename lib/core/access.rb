require_relative 'inspect'

# Groups can Access Instances
class Access
  include Inspect

  INSTANCE_KEY = 'Instance'
  IP_VISIBLE_KEY = 'IP_Visible'
  ADMINISTRATOR_KEY = 'Administrator'

  def initialize group, hash
    self.group = group
    instance_name = hash[INSTANCE_KEY]
    instance = group.scenario.instances.find{ |instance| instance.name == instance_name }
    raise ArgumentError, "Group #{group.name} references non-existant Instance #{instance_name}" unless not instance.nil?
    self.instance = instance
    self.ip_visible = hash[IP_VISIBLE_KEY] || false
    self.administrator = hash[ADMINISTRATOR_KEY] || false
  end

  def to_hash
    {
      INSTANCE_KEY => instance.name,
      IP_VISIBLE_KEY => ip_visible?,
      ADMINISTRATOR_KEY => administrator?
    }
  end

  def ip_visible?
    @ip_visible
  end

  def administrator?
    @administrator
  end

  attr_reader :group, :instance
  attr_writer :group, :instance, :ip_visible, :administrator

end

