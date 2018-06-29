
# Groups can Access Instances
class Access

  INSTANCE_KEY = 'Instance'
  IP_VISIBLE_KEY = 'IP_Visible'
  ADMINISTRATOR_KEY = 'Administrator'

  def initialize group, hash
    self.group = group
    self.instance = group.scenario.instances.find{ |instance| instance.name == hash[INSTANCE_KEY] }
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

