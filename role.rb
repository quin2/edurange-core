require_relative 'recipe'

class Role
  NAME_KEY = 'Name'

  attr_accessor :scenario, :name, :packages, :recipes

  def initialize scenario, hash
    self.name = hash[NAME_KEY]
    package_names = hash['Packages'] || []
    self.packages = package_names
    recipe_names = hash['Recipes'] || []
    self.recipes = recipe_names.map{ |recipe_name| Recipe.new scenario, recipe_name }
  end

  def to_hash
    {
      NAME_KEY => name,
      'Packages' => packages,
      'Recipes' => recipes.map{ |recipe| recipe.name }
    }
  end

  private

  attr_writer :name, :packages, :recipes

end
