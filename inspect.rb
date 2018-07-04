
# uses objects to_hash method for pretty inspect
module Inspect

  def inspect
    to_hash.to_yaml
  end

end

