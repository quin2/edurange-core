
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

  def content_for instance
    to_script @recipe.text_for instance
  end

  private

  def to_script recipe_contents
    eval recipe_contents
    x = "#{name} {"
    x += "  echo running script #{name}\n"
    x += "  su #{@user}\n" if @user
    x += "  cd #{@cwd}\n" if @cwd
    x += "  #{@code}\n" if @code
    x += "  exit\n" if @user # su creates new session that must be exited
    x += "  echo done running script #{name}\n"
    x += "}\n"
    if @not_if
      x += "if ! (#{@not_if}); then #{name}(); fi\n"
    else
      x += "#{name}();\n"
    end
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
    raise "Recipe to Script adapter does not handle method '#{method_id}'" if SCRIP_METHODS.include? method_id.id2name
    super
  end

end

