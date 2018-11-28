require 'openssl'

# adapted from https://github.com/edurange/edurange-server/blob/1f693bb2fdd5ab6ca29d494b87cf26c9ae73e349/lib/variable.rb

class Variable
  attr_reader :name, :type

  # TODO since the rules for name are the same everywhere, DRY it up.
  def self.validate_name name
    raise ArgumentError, "Variable #{NAME_KEY} must not be blank" unless name
    raise ArgumentError, "Variable '#{NAME_KEY}' can only contain alphanumeric characters and underscores" if /\W/.match name
    name
  end

  KNOWN_TYPES = ['string', 'random', 'openssl_pkey_rsa']

  def self.validate_type type
    raise ArgumentError, "Variable #{TYPE_KEY} must not be blank" unless type
    raise ArgumentError, "#{self.class.name} #{TYPE_KEY} '#{type}' is unknown. Must be one of #{KNOWN_TYPES.join ', '}" unless KNOWN_TYPES.include? type
    return type
  end

  def self.validate_value(type, value)
    raise ArgumentError, "Variable #{VALUE_KEY} must not be blank when #{TYPE_KEY} is string" if value.blank? and type == 'string'
    value
  end

  # NOTE: this is non deterministic, it will potentially return a completely different value on different calls.
  def value
    # TODO: switching on type is a code smell. These are really different subclasses of a variables class.
    case type
    when 'string'
      return @value
    when 'random'
      return SecureRandom.hex(4)
    when 'openssl_pkey_rsa'
      return OpenSSL::PKey::RSA.new(2048).to_pem
    else
      raise "Unhandled type #{type}"
    end
  end

  def initialize(name, type, value)
    @name = Variable.validate_name(name)
    @type = Variable.validate_type(type)
    @value = Variable.validate_value(type, value)
  end

  NAME_KEY = 'Name'
  VALUE_KEY = 'Value'
  TYPE_KEY = 'Type'

  def self.from_hash hash
    name = hash[NAME_KEY]
    type = hash[TYPE_KEY]
    value = hash[VALUE_KEY]
    Variable.new(name, type, value)
  end

  def to_h
    {
      NAME_KEY: name,
      TYPE_KEY: type,
      VALUE_KEY: value,
    }
  end

end
