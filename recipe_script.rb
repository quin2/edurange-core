
# turns (some) chef script recipes into (bash) scripts
# Useful for if you want to pretend a scenario is configured using bash scripts instead of chef recipes.
# This is kind of a hack and not a great solution.
# It only sort of implements the functionality used by recipes found in edurange
# I just want to be able to work with scnearios without a dependency on chef.
class RecipeScript

  def initialize recipe
    @recipe = recipe
  end

  def name
    @recipe.name
  end

  def commands_for instance
    builder = RecipeBuilder.new @recipe.name
    recipe_source = @recipe.text_for instance
    # evaluate the recipe in the context of the builder
    builder.instance_eval recipe_source
    builder.commands
  end

  def script_for instance
    commands = commands_for instance
    commands.join "\n\n"
  end

  private

  class RecipeBuilder

    def initialize name
      @resources = []
    end

    def commands
      @resources.flat_map do |resource|
        resource.commands
      end
    end

    private

    # the following methods might be invoked by the recipe

    def script name, &block
      builder = ScriptBuilder.new name
      # execute the script block in the context of the builer
      builder.instance_exec(&block)
      @resources << builder
    end

    def package name, &block
      builder = PackageBuilder.new name
      builder.instance_exec(&block)
      @resources << builder
    end

    def bash name, &block
      builder = BashBuilder.new name
      builder.instance_exec(&block)
      @resources << builder
    end

    def user name, &block
      builder = UserBuilder.new name
      builder.instance_exec(&block)
      @resources << builder
    end

    def group name, &block
      builder = GroupBuilder.new name
      builder.instance_exec(&block)
      @resources << builder
    end

  end

  class UserBuilder

    def initialize name
      @user = name
      @supports = {}
    end

    def supports hash
      @supports.merge! hash
    end

    def password pw
      @password = pw
    end

    def home home
      @home = home
    end

    def group group
      @group = group
    end

    def shell shell
      @shell = shell
    end

    def action action
      raise 'user only supportes create action' unless action == :create
    end

    def commands
      options = ['useradd']
      options << "--homedir #{@home}" if @home
      options << "--create-home" if @home
      options << "--shell #{@shell}" if @shell
      options << "--gid #{@group}" if @group
      options << "--password #{@password}" if @password
      options << @user
      (options.join ' ') + ';'
    end

  end

  class GroupBuilder

    def initialize name
      @group = name
      @members = []
    end

    def members members
      if members.respond_to? :map then
        @members = members
      else
        @members = [members]
      end
    end

    def commands
      ["addgroup #{@group};"] << @members.map do |user|
        "usermod -aG #{@group} #{user};"
      end
    end

  end

  class PackageBuilder

    def initialize name
      @name = name
      @options = []
    end

    def options options
      if options.is_a? Array then
        @options = options
      else
        @options = [options]
      end
    end

    def commands
      terms = ['apt-get install']
      terms += @options
      terms << @name
      (terms.join ' ') + ';'
    end

  end

  class BashBuilder

    def initialize name
      @name = name
    end

    def user u
      @user = u
    end

    def code c
      @code = c
    end

    def commands
      cs = []
      cs << "su #{@user}" if @user
      cs << @code if @code
      cs << 'exit' if @user
      cs
    end

  end

  class ScriptBuilder

    def initialize name
      @name = name
    end

    # the following methods might be invoked by the script resource

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

    DEFAULT_CWD = '/'

    def commands
      commands = []
      commands << "echo running Recipe #{@name} as bash script;"
      commands << "su #{@user};" if @user
      commands << (@cwd ? "cd #{@cwd};" : "cd #{DEFAULT_CWD};")
      commands << @code if @code
      commands << "exit;" if @user # su creates new session that must be exited
      commands << "echo done running Recipe #{@name} as bash script;"
      return commands
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

end

