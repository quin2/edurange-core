
# turns (some) chef script recipes into (bash) scripts
# useful for if you want to pretend a scenario is configured using bash scripts instead of chef recipes.
class RecipeScript

  def initialize recipe
    @recipe = recipe
  end

  def name
    @recipe.name
  end

  def content
    to_script @recipe.text
  end

#  def content_for instance
#    to_script @recipe.text_for instance
#  end

  def commands_for instance
    to_commands @recipe.text_for instance
  end

  def script_for instance
    to_script @recipe.text_for instance
  end

  private

  DEFAULT_CWD = '/'

  def to_commands recipe_contents
    eval recipe_contents
    commands = []
    commands << "echo running Recipe #{name} as bash script;"
    commands << "su #{@user};" if @user
    commands << (@cwd ? "cd #{@cwd};" : "cd #{DEFAULT_CWD};")
    commands << @code if @code
    commands << "exit;" if @user # su creates new session that must be exited
    commands << "echo done running Recipe #{name} as bash script;"
    return commands
  end

  def to_script recipe_contents
    commands = to_commands recipe_contents
    return commands.join "\n"
    #if @not_if
    #  x += "if ! (#{@not_if}); then #{name}(); fi\n"
    #else
    #  x += "#{name}();\n"
    #end
  end

  # the following methods might be invoked by the recipe

  def script name
    @script = name
    yield
  end

  def user name
    @user = name
  end

  def cwd pathname
    @cwd = pathname
  end

  def code c
    @code = c
  end

  def interpreter name
    raise "Recipe to Script adapter only handles 'bash' interpreter" unless name == 'bash'
  end

  def not_if command
    @not_if = command
  end

  # These are methods available to {Chef script resources}[https://docs.chef.io/resource_script.html]
  SCRIPT_METHODS = 'code' \
      , 'creates' \
      , 'cwd' \
      , 'environment' \
      , 'flags' \
      , 'group' \
      , 'interpreter' \
      , 'notifies' \
      , 'path' \
      , 'returns' \
      , 'subscribes' \
      , 'timeout' \
      , 'user' \
      , 'password' \
      , 'domain' \
      , 'umask' \
      , 'action' \

  # Provide a more informative message if script resource attempts to call method we do not implement.
  def method_missing method_id, *arguments, &block
    raise "Recipe to Script adapter does not handle method '#{method_id}'" if SCRIPT_METHODS.include? method_id.id2name
    super
  end

end

