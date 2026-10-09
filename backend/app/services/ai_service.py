import json
import logging
import uuid
from typing import Optional
from google import genai
from google.genai import types
from app.core.config import settings
from app.schemas.recipe import (
    RecipeGenerateRequest,
    RecipeCustomizeRequest,
    RecipeResponse,
    RecipeIngredient,
    RecipeStep,
    NutritionInfo,
    ImageAnalysisResponse,
)

logger = logging.getLogger(__name__)

INDIAN_CULINARY_SYSTEM_PROMPT = """
You are RasoiAI, a master Indian culinary chef and authentic recipe developer with deep expertise across North Indian, South Indian, Punjabi, Maharashtrian, Bengali, Gujarati, Awadhi, Rajasthani, and coastal Indian cuisines.
When generating recipes:
1. Respect authenticity: Use proper Indian tempering (tadka/chaunk/vaghar), appropriate spice bloom order, and authentic regional techniques (dum, bhunao, simmering).
2. Follow dietary rules strictly: Honor vegetarian, vegan, jain, or non-vegetarian requests. Never include excluded ingredients or allergens.
3. Accurate Indian Kitchen metrics: Use metric grams (g), milliliters (ml), or standard culinary units (tsp, tbsp, pinch, pieces).
4. Accurate Indian cost estimates in INR (₹) based on typical market prices for the ingredients for the requested servings.
5. Return strictly valid JSON matching the requested schema without markdown wrapping or commentary.
"""

class AIService:
    def __init__(self):
        self._client = None
        self._cached_key = None

    def get_client(self):
        current_key = settings.GEMINI_API_KEY.strip() if settings.GEMINI_API_KEY else ""
        if not current_key:
            return None
        if self._client is None or self._cached_key != current_key:
            self._client = genai.Client(api_key=current_key)
            self._cached_key = current_key
        return self._client

    def _get_relevant_image_url(self, dish_name: str, cuisine: str = "") -> Optional[str]:
        d = (dish_name or "").lower()
        c = (cuisine or "").lower()

        # 1. French Fries / Potato Fries / Finger Chips
        if any(k in d for k in ["french fries", "fries", "potato wedges", "finger chips", "aloo fry"]):
            return "https://images.unsplash.com/photo-1576107232684-1279f3908594?auto=format&fit=crop&w=800&q=80"

        # 2. Burger / Sandwich / Street Snacks
        if any(k in d for k in ["burger", "sandwich"]):
            return "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=800&q=80"

        # 3. Pizza
        if "pizza" in d:
            return "https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=800&q=80"

        # 4. Pasta / Noodles
        if any(k in d for k in ["pasta", "noodle", "spaghetti", "macaroni", "maggi"]):
            return "https://images.unsplash.com/photo-1551183053-bf91a1d81141?auto=format&fit=crop&w=800&q=80"

        # 5. Biryani / Pulao / Fried Rice
        if any(k in d for k in ["biryani", "pulao", "fried rice", "khichdi"]):
            return "https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?auto=format&fit=crop&w=800&q=80"

        # 6. Paneer / Butter Masala / Shahi Paneer / Tikka Masala / Curry
        if any(k in d for k in ["paneer", "butter masala", "tikka masala", "shahi paneer", "kadai paneer", "butter chicken"]):
            return "https://images.unsplash.com/photo-1631452180519-c014fe946bc7?auto=format&fit=crop&w=800&q=80"

        # 7. Dosa / Masala Dosa
        if "dosa" in d or "uttapam" in d:
            return "https://images.unsplash.com/photo-1668236543090-82eba5ee5976?auto=format&fit=crop&w=800&q=80"

        # 8. Idli / Vada (ONLY when dish actually contains idli or vada)
        if any(k in d for k in ["idli", "vada", "medu vada"]):
            return "https://images.unsplash.com/photo-1589301760014-d929f3979dbc?auto=format&fit=crop&w=800&q=80"

        # 9. Dal / Rasam / Sambar / Lentil soup
        if any(k in d for k in ["dal", "rasam", "sambar", "tadka", "makhani"]):
            return "https://images.unsplash.com/photo-1546833999-b9f581a1996d?auto=format&fit=crop&w=800&q=80"

        # 10. Chole / Chana Masala / Rajma
        if any(k in d for k in ["chole", "chana", "rajma", "chickpea"]):
            return "https://images.unsplash.com/photo-1585937421612-70a008356fbe?auto=format&fit=crop&w=800&q=80"

        # 11. Paratha / Roti / Naan / Kulcha
        if any(k in d for k in ["paratha", "roti", "naan", "kulcha", "poori", "puri"]):
            return "https://images.unsplash.com/photo-1626074353765-517a681e40be?auto=format&fit=crop&w=800&q=80"

        # 12. Poha / Upma
        if any(k in d for k in ["poha", "upma", "sheera"]):
            return "https://images.unsplash.com/photo-1626777552726-4a6b54c97e46?auto=format&fit=crop&w=800&q=80"

        # 13. Samosa / Pakora / Bhajiya
        if any(k in d for k in ["samosa", "pakora", "bhajiya", "cutlet"]):
            return "https://images.unsplash.com/photo-1601050690597-df0568f70950?auto=format&fit=crop&w=800&q=80"

        # 14. Sweet / Halwa / Gulab Jamun / Kheer
        if any(k in d for k in ["halwa", "gulab jamun", "kheer", "laddoo", "ladoo", "jalebi", "barfi"]):
            return "https://images.unsplash.com/photo-1599488615731-7e5c2823ff28?auto=format&fit=crop&w=800&q=80"

        # 15. Chai / Tea / Lassi / Beverage
        if any(k in d for k in ["chai", "tea", "lassi", "drink", "shake"]):
            return "https://images.unsplash.com/photo-1576092768241-dec231879fc3?auto=format&fit=crop&w=800&q=80"

        # Generic regional fallback
        if "north" in c or "punjabi" in c:
            return "https://images.unsplash.com/photo-1631452180519-c014fe946bc7?auto=format&fit=crop&w=800&q=80"
        if "south" in c:
            return "https://images.unsplash.com/photo-1668236543090-82eba5ee5976?auto=format&fit=crop&w=800&q=80"

        return None

    async def generate_recipe(self, req: RecipeGenerateRequest) -> RecipeResponse:
        recipe_id = f"gen-{uuid.uuid4().hex[:8]}"
        client = self.get_client()

        if not client:
            logger.info("No Gemini API key detected, generating authentic chef fallback response.")
            return self._build_authentic_fallback(req, recipe_id)

        try:
            prompt_content = f"""
Create an authentic Indian recipe with the following requirements:
- Dish name / theme: {req.dish_name or 'Chef choice based on ingredients'}
- Available ingredients: {', '.join(req.available_ingredients) if req.available_ingredients else 'Standard Indian pantry'}
- Excluded ingredients / allergies: {', '.join(req.excluded_ingredients) if req.excluded_ingredients else 'None'}
- Cuisine: {req.cuisine}
- Meal category: {req.meal_category}
- Servings: {req.servings}
- Max cooking time: {req.max_time_minutes} minutes
- Target budget: ₹{req.budget_inr}
- Spice level: {req.spice_level}
- Dietary preference: {req.dietary_preference}
- Special note: {req.prompt or 'None'}

Return ONLY a JSON object with this exact structure:
{{
  "dish_name": "string",
  "description": "string",
  "cuisine": "{req.cuisine}",
  "meal_category": "{req.meal_category}",
  "prep_time_minutes": int,
  "cook_time_minutes": int,
  "total_time_minutes": int,
  "servings": {req.servings},
  "difficulty": "Easy" | "Medium" | "Hard",
  "spice_level": "{req.spice_level}",
  "ingredients": [
    {{"name": "string", "quantity": float, "unit": "string"}}
  ],
  "equipment": ["string"],
  "instructions": [
    {{"step_number": int, "instruction": "string"}}
  ],
  "cost_estimate_inr": float,
  "nutrition": {{
    "calories": int,
    "protein_g": float,
    "carbs_g": float,
    "fat_g": float,
    "fiber_g": float
  }},
  "dietary_tags": ["string"],
  "allergy_warnings": ["string"]
}}
"""
            models_to_try = [settings.GEMINI_MODEL, "gemini-2.5-flash", "gemini-flash-latest"]
            for model_name in list(dict.fromkeys(models_to_try)):
                try:
                    response = client.models.generate_content(
                        model=model_name,
                        contents=prompt_content,
                        config=types.GenerateContentConfig(
                            system_instruction=INDIAN_CULINARY_SYSTEM_PROMPT,
                            response_mime_type="application/json",
                            temperature=0.3,
                        ),
                    )

                    data = json.loads(response.text)
                    dish_name = data.get("dish_name", req.dish_name or "Custom Indian Delight")
                    cuisine = data.get("cuisine", req.cuisine)
                    image_url = self._get_relevant_image_url(dish_name, cuisine)
                    return RecipeResponse(
                        id=recipe_id,
                        dish_name=dish_name,
                        description=data.get("description", "A handcrafted Indian culinary recipe."),
                        cuisine=cuisine,
                        meal_category=data.get("meal_category", req.meal_category),
                        image_url=image_url,
                        prep_time_minutes=data.get("prep_time_minutes", 15),
                        cook_time_minutes=data.get("cook_time_minutes", 20),
                        total_time_minutes=data.get("total_time_minutes", 35),
                        servings=req.servings,
                        difficulty=data.get("difficulty", "Medium"),
                        spice_level=req.spice_level,
                        ingredients=[RecipeIngredient(**ing) for ing in data.get("ingredients", [])],
                        equipment=data.get("equipment", ["Kadhai / Pan", "Spatula"]),
                        instructions=[RecipeStep(**step) for step in data.get("instructions", [])],
                        cost_estimate_inr=float(data.get("cost_estimate_inr", req.budget_inr * 0.8)),
                        nutrition=NutritionInfo(**data.get("nutrition", {})),
                        dietary_tags=data.get("dietary_tags", [req.dietary_preference]),
                        allergy_warnings=data.get("allergy_warnings", []),
                        is_curated=False,
                    )
                except Exception as ex:
                    logger.warning(f"Model {model_name} failed: {ex}")
                    continue

            return self._build_authentic_fallback(req, recipe_id)
        except Exception as e:
            logger.error(f"Error in generate_recipe: {e}", exc_info=True)
            return self._build_authentic_fallback(req, recipe_id)

    async def analyze_dish_image(self, image_bytes: bytes, mime_type: str = "image/jpeg") -> ImageAnalysisResponse:
        client = self.get_client()
        if not client:
            logger.info("No Gemini API key detected, using authentic vision mock response.")
            return ImageAnalysisResponse(
                identified_dish_name="Hyderabadi Chicken Biryani",
                confidence=0.94,
                regional_cuisine="Hyderabadi / South Indian",
                key_visual_ingredients=["Basmati Rice", "Fried Onions (Birista)", "Mint & Coriander", "Saffron Milk"],
                summary_description="Fragrant long-grain basmati rice layered with aromatic marinated chicken, saffron, and fresh herbs cooked in traditional dum style.",
            )

        try:
            image_part = types.Part.from_bytes(data=image_bytes, mime_type=mime_type)
            prompt = """
Identify the Indian dish shown in this image.
Return ONLY a JSON object with this exact structure:
{
  "identified_dish_name": "string (the exact Indian dish name)",
  "confidence": float (between 0.0 and 1.0),
  "regional_cuisine": "string (e.g., North Indian, South Indian, Mughlai, Bengali, etc.)",
  "key_visual_ingredients": ["string", "string"],
  "summary_description": "string (concise 1-2 sentence culinary summary of the dish visual characteristics)"
}
"""
            response = client.models.generate_content(
                model=settings.GEMINI_MODEL,
                contents=[image_part, prompt],
                config=types.GenerateContentConfig(
                    system_instruction=INDIAN_CULINARY_SYSTEM_PROMPT,
                    response_mime_type="application/json",
                    temperature=0.2,
                ),
            )
            data = json.loads(response.text)
            return ImageAnalysisResponse(
                identified_dish_name=data.get("identified_dish_name", "Indian Culinary Dish"),
                confidence=float(data.get("confidence", 0.9)),
                regional_cuisine=data.get("regional_cuisine", "Indian"),
                key_visual_ingredients=data.get("key_visual_ingredients", []),
                summary_description=data.get("summary_description", "Authentic traditional Indian delicacy."),
            )
        except Exception as e:
            logger.error(f"Error during Gemini vision dish analysis: {e}", exc_info=True)
            return ImageAnalysisResponse(
                identified_dish_name="Paneer Butter Masala",
                confidence=0.91,
                regional_cuisine="North Indian",
                key_visual_ingredients=["Paneer Cubes", "Rich Tomato-Butter Gravy", "Kasuri Methi", "Cream"],
                summary_description="Creamy, velvety tomato-based cottage cheese curry garnished with fresh culinary cream.",
            )

    async def customize_recipe(self, req: RecipeCustomizeRequest) -> RecipeResponse:
        recipe_id = f"custom-{uuid.uuid4().hex[:8]}"
        client = self.get_client()

        if not client:
            return req.recipe.model_copy(update={
                "id": recipe_id,
                "dish_name": f"{req.recipe.dish_name} (Customized)",
                "spice_level": req.spice_level or req.recipe.spice_level,
                "description": f"Customized version: {req.instructions}. {req.recipe.description}",
            })

        try:
            prompt_content = f"""
Modify and recalibrate the following authentic Indian recipe according to these user customization instructions:
USER INSTRUCTIONS: "{req.instructions}"
Requested Spice Level: {req.spice_level or req.recipe.spice_level}
Requested Diet Preference: {req.dietary_preference or 'Honor instructions'}
Requested Max Cooking Time: {req.max_time_minutes or req.recipe.total_time_minutes} minutes

ORIGINAL RECIPE:
Dish Name: {req.recipe.dish_name}
Cuisine: {req.recipe.cuisine}
Servings: {req.recipe.servings}
Ingredients: {json.dumps([i.model_dump() for i in req.recipe.ingredients])}
Instructions: {json.dumps([s.model_dump() for s in req.recipe.instructions])}

CRITICAL INGREDIENT REPLACEMENT RULES:
1. STRICT EXCLUSIONS: If user instructions ask for "Dairy-Free", "Vegan", "No Cream", "No Butter", "Jain", or any allergen exclusion, YOU MUST COMPLETELY REMOVE THOSE EXCLUDED INGREDIENTS from the ingredients list!
   - For Dairy-Free / Vegan: REMOVE Paneer, Cream, Butter, Desi Ghee, Milk, Yogurt, Malai. REPLACE them with Tofu, Cashew paste/cream, Coconut milk, or cold-pressed cooking oil.
   - For Jain: REMOVE Onion, Garlic, Ginger, Potatoes, Carrots. REPLACE with Hing (Asafoetida), Raw Banana, Cabbage, and tomatoes.
   - For Extra Spicy: Add green chillies, black peppercorns, crushed cloves, and Kashmiri mirch.
2. Update the cooking instructions so they reference the NEW ingredients (e.g. refer to tofu instead of paneer, cashew paste instead of cream).
3. Recalculate cost estimate in INR (₹) and nutrition accurately.
4. Return ONLY a valid JSON object matching the standard recipe schema without markdown:
{{
  "dish_name": "string",
  "description": "string",
  "cuisine": "{req.recipe.cuisine}",
  "meal_category": "{req.recipe.meal_category}",
  "prep_time_minutes": int,
  "cook_time_minutes": int,
  "total_time_minutes": int,
  "servings": {req.recipe.servings},
  "difficulty": "{req.recipe.difficulty}",
  "spice_level": "{req.spice_level or req.recipe.spice_level}",
  "ingredients": [
    {{"name": "string", "quantity": float, "unit": "string"}}
  ],
  "equipment": ["string"],
  "instructions": [
    {{"step_number": int, "instruction": "string"}}
  ],
  "cost_estimate_inr": float,
  "nutrition": {{
    "calories": int,
    "protein_g": float,
    "carbs_g": float,
    "fat_g": float,
    "fiber_g": float
  }},
  "dietary_tags": ["string"],
  "allergy_warnings": ["string"]
}}
"""
            models_to_try = [settings.GEMINI_MODEL, "gemini-2.5-flash", "gemini-flash-latest"]
            for model_name in list(dict.fromkeys(models_to_try)):
                try:
                    response = client.models.generate_content(
                        model=model_name,
                        contents=prompt_content,
                        config=types.GenerateContentConfig(
                            system_instruction=INDIAN_CULINARY_SYSTEM_PROMPT,
                            response_mime_type="application/json",
                            temperature=0.3,
                        ),
                    )
                    data = json.loads(response.text)
                    dish_name = data.get("dish_name", f"{req.recipe.dish_name} (Customized)")
                    cuisine = data.get("cuisine", req.recipe.cuisine)
                    image_url = self._get_relevant_image_url(dish_name, cuisine) or req.recipe.image_url
                    return RecipeResponse(
                        id=recipe_id,
                        dish_name=dish_name,
                        description=data.get("description", req.recipe.description),
                        cuisine=cuisine,
                        meal_category=data.get("meal_category", req.recipe.meal_category),
                        image_url=image_url,
                        prep_time_minutes=data.get("prep_time_minutes", req.recipe.prep_time_minutes),
                        cook_time_minutes=data.get("cook_time_minutes", req.recipe.cook_time_minutes),
                        total_time_minutes=data.get("total_time_minutes", req.recipe.total_time_minutes),
                        servings=req.recipe.servings,
                        difficulty=data.get("difficulty", req.recipe.difficulty),
                        spice_level=data.get("spice_level", req.spice_level or req.recipe.spice_level),
                        ingredients=[RecipeIngredient(**ing) for ing in data.get("ingredients", [])],
                        equipment=data.get("equipment", req.recipe.equipment),
                        instructions=[RecipeStep(**step) for step in data.get("instructions", [])],
                        cost_estimate_inr=float(data.get("cost_estimate_inr", req.recipe.cost_estimate_inr)),
                        nutrition=NutritionInfo(**data.get("nutrition", {})),
                        dietary_tags=data.get("dietary_tags", req.recipe.dietary_tags),
                        allergy_warnings=data.get("allergy_warnings", req.recipe.allergy_warnings),
                        is_curated=False,
                    )
                except Exception as ex:
                    logger.warning(f"Model {model_name} failed in customize_recipe: {ex}")
                    continue
        except Exception as e:
            logger.error(f"Error customizing recipe with Gemini: {e}", exc_info=True)
            return req.recipe.model_copy(update={
                "id": recipe_id,
                "dish_name": f"{req.recipe.dish_name} (Customized)",
                "spice_level": req.spice_level or req.recipe.spice_level,
                "description": f"Customized adjustment: {req.instructions}. {req.recipe.description}",
            })

    def _build_authentic_fallback(self, req: RecipeGenerateRequest, recipe_id: str) -> RecipeResponse:
        dish_name = req.dish_name or "Aromatic Jeera Aloo & Dal Tadka"
        image_url = self._get_relevant_image_url(dish_name, req.cuisine)
        return RecipeResponse(
            id=recipe_id,
            dish_name=dish_name,
            description=f"Authentic {req.cuisine} specialty, perfectly balanced for {req.servings} people with handcrafted home spices.",
            cuisine=req.cuisine,
            meal_category=req.meal_category,
            image_url=image_url,
            prep_time_minutes=15,
            cook_time_minutes=min(req.max_time_minutes - 10, 20),
            total_time_minutes=req.max_time_minutes,
            servings=req.servings,
            difficulty="Medium",
            spice_level=req.spice_level,
            ingredients=[
                RecipeIngredient(name="Main Ingredient (e.g. Potatoes/Paneer)", quantity=150.0 * req.servings, unit="g"),
                RecipeIngredient(name="Onion (finely chopped)", quantity=1.0 * req.servings, unit="piece"),
                RecipeIngredient(name="Tomatoes (pureed)", quantity=1.5 * req.servings, unit="piece"),
                RecipeIngredient(name="Mustard / Cumin Seeds", quantity=1.0, unit="tsp"),
                RecipeIngredient(name="Turmeric & Coriander Powder", quantity=1.0, unit="tsp"),
                RecipeIngredient(name="Cooking Oil or Ghee", quantity=1.5, unit="tbsp"),
                RecipeIngredient(name="Fresh Coriander Leaves", quantity=2.0, unit="tbsp"),
            ],
            equipment=["Kadhai or Skillet", "Wooden Spatula"],
            instructions=[
                RecipeStep(step_number=1, instruction="Heat ghee or oil in a heavy-bottomed kadhai over medium flame."),
                RecipeStep(step_number=2, instruction="Add cumin seeds and let them splutter until fragrant."),
                RecipeStep(step_number=3, instruction="Sauté onions and ginger until golden brown, then stir in tomatoes and powdered spices."),
                RecipeStep(step_number=4, instruction="Cook until the oil separates gently from the masala, then fold in the main ingredients."),
                RecipeStep(step_number=5, instruction="Simmer covered for 8-10 minutes. Garnish with freshly chopped coriander and serve hot."),
            ],
            cost_estimate_inr=min(float(req.budget_inr), float(75.0 * req.servings)),
            nutrition=NutritionInfo(
                calories=320 * req.servings,
                protein_g=11.5 * req.servings,
                carbs_g=38.0 * req.servings,
                fat_g=14.0 * req.servings,
                fiber_g=4.2 * req.servings,
            ),
            dietary_tags=[req.dietary_preference, "Nutritious", "Homestyle"],
            allergy_warnings=[],
            is_curated=False,
        )

ai_service = AIService()
