require_relative 'recipe'
require_relative 'package'

class Role
  NAME_KEY = 'Name'
  PACKAGES_KEY = 'Packages'
  RECIPES_KEY = 'Recipes'

  attr_reader :scenario, :name, :packages, :recipes

  def initialize scenario, hash
    self.name = hash[NAME_KEY]
    package_names = hash[PACKAGES_KEY] || []
    self.packages = package_names.map{ |package_name| Package.new package_name }
    recipe_names = hash[RECIPES_KEY] || []
    self.recipes = recipe_names.map{ |recipe_name| Recipe.new scenario, recipe_name }
  end

  def to_hash
    {
      NAME_KEY => name,
      PACKAGES_KEY => packages.map{ |package| package.name },
      RECIPES_KEY => recipes.map{ |recipe| recipe.name }
    }
  end

  #def scripts
  #  []
  #end

  private

  attr_writer :packages, :recipes

  def name= name
    raise "Role #{NAME_KEY} must not be empty" if name.blank?
    raise "Role #{NAME_KEY} '#{name}' does not only contain alphanumeric characters and underscores" if /\W/.match name
    @name = name
  end

end
