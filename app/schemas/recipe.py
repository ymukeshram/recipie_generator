from typing import List, Optional
from pydantic import BaseModel, Field

class RecipeIngredient(BaseModel):
    name: str
    quantity: float
    unit: str

class RecipeStep(BaseModel):
    step_number: int
    instruction: str

class NutritionInfo(BaseModel):
    calories: int = 0
    protein_g: float = 0.0
    carbs_g: float = 0.0
    fat_g: float = 0.0
    fiber_g: float = 0.0

class RecipeGenerateRequest(BaseModel):
    dish_name: Optional[str] = Field(None, description="Traditional or colloquial dish name")
    available_ingredients: Optional[List[str]] = Field(default_factory=list, description="Pantry ingredients available in kitchen")
    excluded_ingredients: Optional[List[str]] = Field(default_factory=list, description="Allergens or excluded items")
    prompt: Optional[str] = Field(None, description="Special culinary instructions or flavor notes")
    cuisine: str = Field(default="North Indian", description="Regional cuisine e.g. North Indian, South Indian, Bengali, etc.")
    meal_category: str = Field(default="Dinner", description="Breakfast, Lunch, Dinner, Snacks, Dessert")
    servings: int = Field(default=2, ge=1, le=20, description="Target serving size count")
    max_time_minutes: int = Field(default=30, ge=10, le=180, description="Maximum cooking time in minutes")
    budget_inr: int = Field(default=200, ge=30, le=2000, description="Target approximate grocery cost limit in INR")
    spice_level: str = Field(default="Medium", description="Mild, Medium, Spicy, Extra Spicy")
    dietary_preference: str = Field(default="Vegetarian", description="Vegetarian, Vegan, Eggetarian, Non-Vegetarian")

class RecipeResponse(BaseModel):
    id: str
    dish_name: str
    description: str
    cuisine: str
    meal_category: str
    image_url: Optional[str] = None
    prep_time_minutes: int
    cook_time_minutes: int
    total_time_minutes: int
    servings: int
    difficulty: str
    spice_level: str
    ingredients: List[RecipeIngredient]
    equipment: List[str] = Field(default_factory=list)
    instructions: List[RecipeStep]
    cost_estimate_inr: float
    nutrition: NutritionInfo
    dietary_tags: List[str] = Field(default_factory=list)
    allergy_warnings: List[str] = Field(default_factory=list)
    is_curated: bool = False

class ImageAnalysisResponse(BaseModel):
    identified_dish_name: str
    confidence: float = Field(ge=0.0, le=1.0)
    regional_cuisine: str
    key_visual_ingredients: List[str] = Field(default_factory=list)
    summary_description: str

class RecipeCustomizeRequest(BaseModel):
    recipe: RecipeResponse
    instructions: str = Field(description="Customization prompt e.g. Jain style, vegan, extra spicy, etc.")
    spice_level: Optional[str] = None
    dietary_preference: Optional[str] = None
    max_time_minutes: Optional[int] = None
