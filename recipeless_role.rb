
require_relative 'recipe_script'

# convert all of a Role's recipes into scripts.
class RecipelessRole < SimpleDelegator

  def scripts
    recipes.map{ |recipe| RecipeScript.new recipe }.concat(super.scripts)
  end

  def recipes
    []
  end

end

