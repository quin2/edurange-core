require_relative 'recipe'

class Role
  NAME_KEY = 'Name'
  PACKAGES_KEY = 'Packages'
  RECIPES_KEY = 'Recipes'

  attr_accessor :scenario, :name, :packages, :recipes

  def initialize scenario, hash
    self.name = hash[NAME_KEY]
    package_names = hash[PACKAGES_KEY] || []
    self.packages = package_names
    recipe_names = hash[RECIPES_KEY] || []
    self.recipes = recipe_names.map{ |recipe_name| Recipe.new scenario, recipe_name }
  end

  def to_hash
    {
      NAME_KEY => name,
      PACKAGES_KEY => packages,
      RECIPES_KEY => recipes.map{ |recipe| recipe.name }
    }
  end

  def scripts
    []
  end

  private

  attr_writer :name, :packages, :recipes

end
