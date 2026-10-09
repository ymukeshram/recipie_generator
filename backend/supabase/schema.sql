-- ==============================================================================
-- RasoiAI - Supabase PostgreSQL Schema with Row Level Security (RLS)
-- ==============================================================================

-- 1. Enable UUID Extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. User Profiles Table (Linked to Supabase Auth)
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT,
    avatar_url TEXT,
    dietary_preference TEXT DEFAULT 'Vegetarian', -- Vegetarian, Vegan, Eggetarian, Non-Vegetarian
    preferred_spice_level TEXT DEFAULT 'Medium', -- Mild, Medium, Spicy, Extra Spicy
    favorite_cuisines TEXT[] DEFAULT ARRAY['North Indian', 'South Indian'],
    allergies TEXT[] DEFAULT ARRAY[]::TEXT[],
    default_servings INT DEFAULT 2,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- 3. Curated Recipes Table (Chef & Heritage Catalog)
CREATE TABLE IF NOT EXISTS public.curated_recipes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dish_name TEXT NOT NULL,
    description TEXT NOT NULL,
    cuisine TEXT NOT NULL,
    meal_category TEXT NOT NULL,
    image_url TEXT,
    prep_time_minutes INT NOT NULL,
    cook_time_minutes INT NOT NULL,
    total_time_minutes INT NOT NULL,
    servings INT DEFAULT 2,
    difficulty TEXT DEFAULT 'Medium',
    spice_level TEXT DEFAULT 'Medium',
    ingredients JSONB NOT NULL,
    equipment TEXT[] DEFAULT ARRAY[]::TEXT[],
    instructions JSONB NOT NULL,
    cost_estimate_inr NUMERIC(10, 2) NOT NULL,
    nutrition JSONB,
    dietary_tags TEXT[] DEFAULT ARRAY[]::TEXT[],
    allergy_warnings TEXT[] DEFAULT ARRAY[]::TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- 4. Generated Recipes Table (AI Generations)
CREATE TABLE IF NOT EXISTS public.generated_recipes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    dish_name TEXT NOT NULL,
    description TEXT NOT NULL,
    cuisine TEXT NOT NULL,
    meal_category TEXT NOT NULL,
    image_url TEXT,
    prep_time_minutes INT NOT NULL,
    cook_time_minutes INT NOT NULL,
    total_time_minutes INT NOT NULL,
    servings INT DEFAULT 2,
    difficulty TEXT DEFAULT 'Medium',
    spice_level TEXT DEFAULT 'Medium',
    ingredients JSONB NOT NULL,
    equipment TEXT[] DEFAULT ARRAY[]::TEXT[],
    instructions JSONB NOT NULL,
    cost_estimate_inr NUMERIC(10, 2) NOT NULL,
    nutrition JSONB,
    dietary_tags TEXT[] DEFAULT ARRAY[]::TEXT[],
    allergy_warnings TEXT[] DEFAULT ARRAY[]::TEXT[],
    source_type TEXT DEFAULT 'prompt', -- 'prompt' or 'photo'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- 5. Saved Recipes Table (Bookmarks & Favorites)
CREATE TABLE IF NOT EXISTS public.saved_recipes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    recipe_id TEXT NOT NULL,
    recipe_type TEXT NOT NULL, -- 'curated' or 'generated'
    dish_name TEXT NOT NULL,
    recipe_data JSONB NOT NULL,
    saved_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    UNIQUE (user_id, recipe_id)
);

-- 6. Generation History Table
CREATE TABLE IF NOT EXISTS public.recipe_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    query_text TEXT,
    input_image_url TEXT,
    generated_recipe_id UUID REFERENCES public.generated_recipes(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- ==============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ==============================================================================

-- Enable RLS on all tables
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.curated_recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.generated_recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.saved_recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.recipe_history ENABLE ROW LEVEL SECURITY;

-- Curated Recipes: Everyone can read
CREATE POLICY "Curated recipes are viewable by all authenticated and anon users"
    ON public.curated_recipes FOR SELECT
    USING (true);

-- User Profiles: Users can view and edit their own profile
CREATE POLICY "Users can view own profile"
    ON public.user_profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
    ON public.user_profiles FOR UPDATE
    USING (auth.uid() = id);

-- Generated Recipes: Users can view and manage their own generations
CREATE POLICY "Users can view own generated recipes"
    ON public.generated_recipes FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own generated recipes"
    ON public.generated_recipes FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Saved Recipes: Users can view and manage their own bookmarks
CREATE POLICY "Users can view own saved recipes"
    ON public.saved_recipes FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own saved recipes"
    ON public.saved_recipes FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own saved recipes"
    ON public.saved_recipes FOR DELETE
    USING (auth.uid() = user_id);

-- Recipe History: Users can view and insert own history
CREATE POLICY "Users can view own history"
    ON public.recipe_history FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own history"
    ON public.recipe_history FOR INSERT
    WITH CHECK (auth.uid() = user_id);
