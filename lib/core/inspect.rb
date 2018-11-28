
# uses objects to_ha method for pretty inspect
module Inspect

  def inspect
    to_h.to_yaml
  end

end

