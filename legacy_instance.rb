require_relative 'instance'

# implements some methods that I think don't belong in Instance but are required by recipes.
class LegacyInstance < DelegateClass(Instance)

  def initialize instance
    super instance
  end

  # TODO actually parse variables
  def variables_instance
    warn 'i dont like this!'
    []
  end

  def variables_player
    warn 'i dont like this!'
    []
  end

  def users
    __getobj__.users.select{ |user| !user.administrator? }
  end

  def administrators
    __getobj__.users.select{ |user| user.administrator? }
  end

  # TODO: i dont like this method: you should just get the players then get their names
  # TODO: I also don't like the naming inconsistency. Is it user or player?!? make up your mind
  # this is included for legacy reasons because some scripts (e.g. treasurehunt) require it.
  def player_names
    groups.flat_map{ |group| group.users }.map{ |user| user.login }
  end

end

