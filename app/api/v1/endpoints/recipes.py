from typing import List, Optional
from fastapi import APIRouter, File, UploadFile, HTTPException, Query
from app.schemas.recipe import (
    RecipeGenerateRequest,
    RecipeCustomizeRequest,
    RecipeResponse,
    ImageAnalysisResponse,
)
from app.services.ai_service import ai_service

router = APIRouter()

# In-memory curated catalog for authentic Indian recipes
CURATED_RECIPES = [
    {
        "id": "curated-1",
        "dish_name": "Paneer Butter Masala",
        "description": "A rich, creamy, and mildly sweet North Indian curry made with cottage cheese in tomato-butter gravy.",
        "cuisine": "North Indian",
        "meal_category": "Dinner",
        "image_url": "https://images.unsplash.com/photo-1631452180519-c014fe946bc7?auto=format&fit=crop&w=800&q=80",
        "prep_time_minutes": 15,
        "cook_time_minutes": 25,
        "total_time_minutes": 40,
        "servings": 2,
        "difficulty": "Medium",
        "spice_level": "Mild",
        "ingredients": [
            {"name": "Paneer (Cubes)", "quantity": 200, "unit": "g"},
            {"name": "Ripe Tomatoes", "quantity": 4, "unit": "piece"},
            {"name": "Butter", "quantity": 2, "unit": "tbsp"},
            {"name": "Fresh Cream", "quantity": 3, "unit": "tbsp"},
            {"name": "Ginger-Garlic Paste", "quantity": 1, "unit": "tsp"},
            {"name": "Kasuri Methi", "quantity": 1, "unit": "tsp"},
            {"name": "Garam Masala", "quantity": 0.5, "unit": "tsp"},
            {"name": "Kashmiri Red Chilli Powder", "quantity": 1, "unit": "tsp"},
        ],
        "equipment": ["Kadhai or Pan", "Blender"],
        "instructions": [
            {"step_number": 1, "instruction": "Roughly chop tomatoes and blend into a smooth puree."},
            {"step_number": 2, "instruction": "Melt butter in a kadhai on medium heat, add ginger-garlic paste and sauté for 1 minute."},
            {"step_number": 3, "instruction": "Add tomato puree, Kashmiri chilli powder, and salt. Cook until butter separates."},
            {"step_number": 4, "instruction": "Add paneer cubes and simmer gently for 4 minutes with cream and crushed kasuri methi."},
        ],
        "cost_estimate_inr": 160.0,
        "nutrition": {"calories": 380, "protein_g": 14.5, "carbs_g": 12.0, "fat_g": 30.0, "fiber_g": 3.2},
        "dietary_tags": ["Vegetarian", "High Protein"],
        "allergy_warnings": ["Contains Dairy"],
        "is_curated": True,
    },
    {
        "id": "curated-2",
        "dish_name": "South Indian Tomato Rasam",
        "description": "Tangy and comforting pepper-cumin soup infused with tempered curry leaves and crushed garlic.",
        "cuisine": "South Indian",
        "meal_category": "Lunch",
        "image_url": "https://images.unsplash.com/photo-1546833999-b9f581a1996d?auto=format&fit=crop&w=800&q=80",
        "prep_time_minutes": 10,
        "cook_time_minutes": 15,
        "total_time_minutes": 25,
        "servings": 3,
        "difficulty": "Easy",
        "spice_level": "Spicy",
        "ingredients": [
            {"name": "Tomatoes", "quantity": 3, "unit": "piece"},
            {"name": "Tamarind Pulp", "quantity": 1, "unit": "tbsp"},
            {"name": "Black Pepper & Cumin powder", "quantity": 1.5, "unit": "tsp"},
            {"name": "Garlic cloves", "quantity": 4, "unit": "piece"},
            {"name": "Mustard seeds & Curry leaves", "quantity": 1, "unit": "tsp"},
            {"name": "Ghee or Oil", "quantity": 1, "unit": "tsp"},
        ],
        "equipment": ["Saucepan / Eeya Chombu", "Tadka Ladle"],
        "instructions": [
            {"step_number": 1, "instruction": "Boil mashed tomatoes in tamarind water with turmeric and salt until raw aroma subsides."},
            {"step_number": 2, "instruction": "Add coarsely pounded pepper, cumin, and crushed garlic. Bring to a gentle frothy boil."},
            {"step_number": 3, "instruction": "In a separate ladle, heat ghee, splutter mustard seeds and curry leaves (tadka), and pour into rasam."},
        ],
        "cost_estimate_inr": 45.0,
        "nutrition": {"calories": 85, "protein_g": 2.0, "carbs_g": 14.0, "fat_g": 2.5, "fiber_g": 1.8},
        "dietary_tags": ["Vegetarian", "Comfort Food", "Immunity Boost"],
        "allergy_warnings": [],
        "is_curated": True,
    },
    {
        "id": "curated-3",
        "dish_name": "Homestyle Dal Tadka",
        "description": "Yellow toor dal tempered with ghee, cumin seeds, garlic, and dried red chillies.",
        "cuisine": "North Indian",
        "meal_category": "Dinner",
        "image_url": "https://images.unsplash.com/photo-1546833999-b9f581a1996d?auto=format&fit=crop&w=800&q=80",
        "prep_time_minutes": 10,
        "cook_time_minutes": 20,
        "total_time_minutes": 30,
        "servings": 2,
        "difficulty": "Easy",
        "spice_level": "Medium",
        "ingredients": [
            {"name": "Toor Dal (Pigeon Peas)", "quantity": 150, "unit": "g"},
            {"name": "Pure Desi Ghee", "quantity": 2, "unit": "tbsp"},
            {"name": "Cumin Seeds (Jeera)", "quantity": 1, "unit": "tsp"},
            {"name": "Garlic (finely chopped)", "quantity": 5, "unit": "piece"},
            {"name": "Dried Red Chillies", "quantity": 2, "unit": "piece"},
            {"name": "Hing (Asafoetida)", "quantity": 1, "unit": "pinch"},
        ],
        "equipment": ["Pressure Cooker", "Tadka Ladle"],
        "instructions": [
            {"step_number": 1, "instruction": "Pressure cook washed toor dal with turmeric and salt for 3 whistles."},
            {"step_number": 2, "instruction": "Whisk dal smoothly and adjust consistency with warm water."},
            {"step_number": 3, "instruction": "Heat ghee in a ladle, add jeera, hing, chopped garlic, and dried red chillies until golden."},
            {"step_number": 4, "instruction": "Pour sizzling tadka over dal, cover immediately with lid for 2 mins to trap aroma."},
        ],
        "cost_estimate_inr": 60.0,
        "nutrition": {"calories": 240, "protein_g": 12.0, "carbs_g": 32.0, "fat_g": 7.5, "fiber_g": 5.0},
        "dietary_tags": ["Vegetarian", "High Protein", "Staple"],
        "allergy_warnings": [],
        "is_curated": True,
    }
]

@router.post("/generate", response_model=RecipeResponse)
async def generate_recipe(request: RecipeGenerateRequest):
    """
    Generate an authentic regional Indian recipe using Gemini AI.
    """
    try:
        return await ai_service.generate_recipe(request)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/analyze-image", response_model=ImageAnalysisResponse)
async def analyze_dish_image(file: UploadFile = File(...)):
    """
    Two-step dish identification from uploaded food photo using Gemini Vision.
    """
    try:
        contents = await file.read()
        mime_type = file.content_type or "image/jpeg"
        return await ai_service.analyze_dish_image(contents, mime_type=mime_type)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/curated", response_model=List[RecipeResponse])
async def get_curated_recipes(cuisine: Optional[str] = Query(None)):
    """
    Get curated authentic Indian recipes, optionally filtered by cuisine.
    """
    if cuisine and cuisine != "All":
        filtered = [r for r in CURATED_RECIPES if r["cuisine"].lower() == cuisine.lower()]
        return [RecipeResponse(**r) for r in filtered]
    return [RecipeResponse(**r) for r in CURATED_RECIPES]

@router.post("/customize", response_model=RecipeResponse)
async def customize_recipe(request: RecipeCustomizeRequest):
    """
    Customize and recalibrate an existing authentic Indian recipe using Gemini AI.
    """
    try:
        return await ai_service.customize_recipe(request)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

