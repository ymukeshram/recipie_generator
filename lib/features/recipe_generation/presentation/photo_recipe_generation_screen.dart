import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rasoiai/core/theme/app_colors.dart';
import 'package:rasoiai/core/networking/api_client.dart';
import 'package:rasoiai/shared/widgets/culinary_loading_indicator.dart';
import 'package:rasoiai/core/services/history_service.dart';

class PhotoRecipeGenerationScreen extends StatefulWidget {
  const PhotoRecipeGenerationScreen({super.key});

  @override
  State<PhotoRecipeGenerationScreen> createState() => _PhotoRecipeGenerationScreenState();
}

class _PhotoRecipeGenerationScreenState extends State<PhotoRecipeGenerationScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  bool _isAnalyzing = false;
  bool _isGeneratingRecipe = false;
  String? _identifiedDishName;
  double? _confidence;
  String? _regionalCuisine;
  List<String> _keyVisualIngredients = [];
  String? _summaryDescription;
  String? _errorMessage;
  String _analysisStatusMessage = 'Connecting to RasoiAI Culinary Vision Engine...';
  final TextEditingController _dishNameController = TextEditingController();

  @override
  void dispose() {
    _dishNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImage = image;
          _identifiedDishName = null;
          _confidence = null;
          _regionalCuisine = null;
          _keyVisualIngredients = [];
          _summaryDescription = null;
          _errorMessage = null;
          _dishNameController.clear();
        });
        _analyzeDishImage();
      }
    } catch (_) {}
  }

  Future<void> _analyzeDishImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
      _analysisStatusMessage = 'Connecting to RasoiAI Culinary Vision Engine...';
      _identifiedDishName = null;
      _confidence = null;
      _regionalCuisine = null;
      _keyVisualIngredients = [];
      _summaryDescription = null;
      _dishNameController.clear();
    });

    // Progressive status updates so user clearly sees active progress
    int elapsedSeconds = 0;
    Timer? stageTimer;
    stageTimer = Timer.periodic(const Duration(seconds: 4), (t) {
      elapsedSeconds += 4;
      if (!mounted || !_isAnalyzing) {
        t.cancel();
        return;
      }
      if (elapsedSeconds == 4) {
        setState(() => _analysisStatusMessage = 'Uploading dish photo to AI server...');
      } else if (elapsedSeconds == 10) {
        setState(() => _analysisStatusMessage = 'Waking up cloud culinary server...');
      } else if (elapsedSeconds == 18) {
        setState(() => _analysisStatusMessage = 'Gemini AI is examining ingredients, textures, and curry...');
      } else if (elapsedSeconds >= 30) {
        setState(() => _analysisStatusMessage = 'Identifying authentic Indian dish & regional style...');
      }
    });

    try {
      final bytes = await _selectedImage!.readAsBytes();
      final result = await apiClient.analyzeDishImage(
        bytes,
        _selectedImage!.name,
        onProgress: (msg) {
          if (mounted) setState(() => _analysisStatusMessage = msg);
        },
      );

      stageTimer.cancel();

      if (mounted && result != null) {
        final dishName = (result['identified_dish_name'] as String?)?.trim();
        if (dishName != null && dishName.isNotEmpty) {
          setState(() {
            _isAnalyzing = false;
            _identifiedDishName = dishName;
            _confidence = (result['confidence'] as num?)?.toDouble() ?? 0.95;
            _regionalCuisine = result['regional_cuisine'] as String?;
            _keyVisualIngredients = (result['key_visual_ingredients'] as List<dynamic>?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [];
            _summaryDescription = result['summary_description'] as String?;
            _dishNameController.text = dishName;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('[PhotoRecipe] Error analyzing dish: $e');
    } finally {
      stageTimer.cancel();
    }

    // Never guess or invent a fake dish! Let user know honestly so they can retry or type manually.
    if (mounted) {
      setState(() {
        _isAnalyzing = false;
        _errorMessage =
            'Could not reach AI server or identify the dish. Please verify internet connection and tap Retry, or enter the dish name below.';
      });
    }
  }

  Future<void> _generateRecipeForIdentifiedDish() async {
    final dish = _dishNameController.text.trim();
    if (dish.isEmpty) return;

    setState(() => _isGeneratingRecipe = true);
    try {
      final promptExtra = _summaryDescription != null
          ? 'Authentic preparation matching photograph: $_summaryDescription. Key ingredients detected: ${_keyVisualIngredients.join(", ")}'
          : 'Generate an authentic regional recipe for $dish captured in user photograph.';

      final recipe = await apiClient.generateRecipe(
        dishName: dish,
        prompt: promptExtra,
        cuisine: _regionalCuisine ?? 'North Indian',
      );
      if (mounted) {
        setState(() => _isGeneratingRecipe = false);
        if (recipe != null) {
          historyService.addRecipe(recipe);
          context.push('/recipe/${recipe.id}', extra: recipe);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not generate recipe from server. Please try again.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGeneratingRecipe = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating recipe: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const Text('Identify Dish from Photo'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Clear image capture area with phone camera / gallery buttons
                  Container(
                    height: 240,
                    decoration: BoxDecoration(
                      color: AppColors.cardBg(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder(context)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _selectedImage != null
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              kIsWeb
                                  ? Image.network(_selectedImage!.path, fit: BoxFit.cover)
                                  : Image.file(File(_selectedImage!.path), fit: BoxFit.cover),
                          Positioned(
                            bottom: 10,
                            right: 10,
                            child: CircleAvatar(
                              backgroundColor: Colors.white,
                              radius: 18,
                              child: IconButton(
                                iconSize: 18,
                                icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
                                onPressed: () => _showPickerSheet(),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.surfaceSubtle,
                              ),
                              child: const Icon(Icons.camera_alt_outlined, color: AppColors.textSecondary, size: 26),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Add a photograph of any Indian dish',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Our AI will identify the dish and generate its recipe',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 14),

              // Separate Camera and Gallery Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        side: const BorderSide(color: AppColors.border),
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.photo_camera, size: 18, color: AppColors.textPrimary),
                      label: const Text('Take Photo', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        side: const BorderSide(color: AppColors.border),
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined, size: 18, color: AppColors.textPrimary),
                      label: const Text('Choose File', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Analysis Loading State with rotating progressive stages
              if (_isAnalyzing)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder(context)),
                  ),
                  child: Column(
                    children: [
                      const CulinaryLoadingIndicator(
                        size: 64,
                        message: '',
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _analysisStatusMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text(context),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Analyzing ingredients, textures & culinary presentation with Gemini Vision...',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: AppColors.subtext(context)),
                      ),
                    ],
                  ),
                ),

              // Error State with Retry Button (Never show fake Biryani)
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF2A2016)
                        : const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFF97316).withOpacity(0.4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline, color: Color(0xFFEA580C), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'AI Server Connection',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFFFDBA74)
                                  : const Color(0xFF9A3412),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFFFED7AA)
                              : const Color(0xFF7C2D12),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _analyzeDishImage,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFEA580C),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text('Retry AI Analysis', style: TextStyle(fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _errorMessage = null;
                                _identifiedDishName = '';
                                _dishNameController.clear();
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text('Type Manually', style: TextStyle(color: AppColors.text(context))),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              // Identified Result & Confirmation Step
              if (_identifiedDishName != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Identified Dish',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text(context)),
                              ),
                            ],
                          ),
                          if (_confidence != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD1FAE5),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${((_confidence!) * 100).toInt()}% Match',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF047857)),
                              ),
                            ),
                        ],
                      ),
                      if (_regionalCuisine != null && _regionalCuisine!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.subtleBg(context),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Regional Style: $_regionalCuisine',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.subtext(context)),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Text(
                        'Confirm or edit the dish name:',
                        style: TextStyle(fontSize: 12, color: AppColors.subtext(context)),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _dishNameController,
                        style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.w600, fontSize: 15),
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.restaurant_menu_rounded, size: 20, color: AppColors.subtext(context)),
                          filled: true,
                          fillColor: AppColors.subtleBg(context),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.cardBorder(context))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.cardBorder(context))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.accent, width: 1.5)),
                        ),
                      ),
                      if (_summaryDescription != null && _summaryDescription!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.subtleBg(context),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _summaryDescription!,
                            style: TextStyle(fontSize: 12, color: AppColors.subtext(context), height: 1.3),
                          ),
                        ),
                      ],
                      if (_keyVisualIngredients.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Key Visual Ingredients Detected:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text(context)),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _keyVisualIngredients.map((ing) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.subtleBg(context),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.cardBorder(context)),
                              ),
                              child: Text(
                                ing,
                                style: TextStyle(fontSize: 11, color: AppColors.text(context)),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 16),
                      if (_isGeneratingRecipe)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Center(
                            child: CulinaryLoadingIndicator(
                              size: 54,
                              message: 'Generating authentic recipe with AI...',
                            ),
                          ),
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: _generateRecipeForIdentifiedDish,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.accent : AppColors.textPrimary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                          label: const Text('Generate Recipe for this Dish', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  ),
);
  }

  void _showPickerSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}
