
# simple value class for storing package information.
# could be extended to for instance store package version as well.
class Package

  attr_reader :name

  def initialize name
    @name = name
  end

  def to_s
    name
  end

  def inspect
    to_s
  end

#  def commands_for instance
#    case instance.os
#    when 'ubuntu'
#      ["apt-get install -y #{name}"]
#    when 'nat'
#
#    else
#      raise "Can not install Package #{name} for unknown operating systems #{instance.os}"
#    end
#  end

end

