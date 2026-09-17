import 'package:go_router/go_router.dart';

import 'package:mobile/core/navigation/main_navigation_screen.dart';

import 'package:mobile/features/ai/presentation/screens/explain_recipe_screen.dart';
import 'package:mobile/features/ai/presentation/screens/generate_pantry_recipe_screen.dart';
import 'package:mobile/features/ai/presentation/screens/generate_recipe_screen.dart';

import 'package:mobile/features/authentication/presentation/screens/auth_gate.dart';
import 'package:mobile/features/authentication/presentation/screens/forgot_password_screen.dart';
import 'package:mobile/features/authentication/presentation/screens/login_screen.dart';
import 'package:mobile/features/authentication/presentation/screens/register_screen.dart';
import 'package:mobile/features/authentication/presentation/screens/reset_password_screen.dart';
import 'package:mobile/features/authentication/presentation/screens/verify_registration_screen.dart';

import 'package:mobile/features/checkout/presentation/screens/my_orders_screen.dart';

import 'package:mobile/features/community/presentation/screens/community_post_detail_screen.dart';
import 'package:mobile/features/community/presentation/screens/community_screen.dart';
import 'package:mobile/features/community/presentation/screens/create_community_post_screen.dart';

import 'package:mobile/features/meal_plans/presentation/screens/my_meal_plans_screen.dart';

import 'package:mobile/features/nutrition/presentation/screens/meal_plan_nutrition_screen.dart';
import 'package:mobile/features/nutrition/presentation/screens/recipe_nutrition_screen.dart';

import 'package:mobile/features/pantry/presentation/screens/my_pantry_screen.dart';
import 'package:mobile/features/pantry/presentation/screens/pantry_scan_screen.dart';

import 'package:mobile/features/recipe_video/presentation/screens/generate_recipe_video_screen.dart';

import 'package:mobile/features/recipes/presentation/screens/recipe_detail_screen.dart';

import 'package:mobile/features/weight_loss/presentation/screens/weight_loss_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/auth',
  routes: [
    // =========================================================
    // ROOT
    // =========================================================

    GoRoute(path: '/', redirect: (context, state) => '/auth'),

    // =========================================================
    // AUTHENTICATION
    // =========================================================
    GoRoute(path: '/auth', builder: (context, state) => const AuthGate()),

    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),

    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),

    GoRoute(
      path: '/register/verify',
      builder: (context, state) {
        final email = state.extra as String;
        return VerifyRegistrationScreen(email: email);
      },
    ),

    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),

    GoRoute(
      path: '/forgot-password/reset',
      builder: (context, state) {
        final email = state.extra as String;
        return ResetPasswordScreen(email: email);
      },
    ),

    // =========================================================
    // MAIN NAVIGATION
    // =========================================================
    GoRoute(
      path: '/home',
      builder: (context, state) => const MainNavigationScreen(initialIndex: 0),
    ),

    GoRoute(
      path: '/favorites',
      builder: (context, state) => const MainNavigationScreen(initialIndex: 1),
    ),

    GoRoute(
      path: '/account',
      builder: (context, state) => const MainNavigationScreen(initialIndex: 3),
    ),

    // =========================================================
    // ORDERS
    // =========================================================
    GoRoute(
      path: '/orders',
      builder: (context, state) => const MyOrdersScreen(),
    ),

    // =========================================================
    // PANTRY
    // =========================================================
    GoRoute(
      path: '/pantry',
      builder: (context, state) => const MyPantryScreen(),
    ),

    GoRoute(
      path: '/pantry-scan',
      builder: (context, state) => const PantryScanScreen(),
    ),

    // =========================================================
    // AI
    // =========================================================
    GoRoute(
      path: '/ai/generate-from-pantry',
      builder: (context, state) => const GeneratePantryRecipeScreen(),
    ),

    GoRoute(
      path: '/ai/generate-recipe',
      builder: (context, state) => const GenerateRecipeScreen(),
    ),

    GoRoute(
      path: '/ai/explain-recipe',
      builder: (context, state) => const ExplainRecipeScreen(),
    ),

    // =========================================================
    // RECIPE VIDEO
    // =========================================================
    GoRoute(
      path: '/recipe/:id/video',
      builder: (context, state) {
        final recipeId = state.pathParameters['id']!;
        final recipeTitle = state.uri.queryParameters['title'] ?? 'Recipe';

        return GenerateRecipeVideoScreen(
          recipeId: recipeId,
          recipeTitle: recipeTitle,
        );
      },
    ),

    // =========================================================
    // MEAL PLANS
    // =========================================================
    GoRoute(
      path: '/meal-plans',
      builder: (context, state) => const MyMealPlansScreen(),
    ),

    // =========================================================
    // NUTRITION
    // =========================================================
    GoRoute(
      path: '/recipe/:id/nutrition',
      builder: (context, state) {
        final recipeId = state.pathParameters['id']!;
        return RecipeNutritionScreen(recipeId: recipeId);
      },
    ),

    GoRoute(
      path: '/meal-plans/:id/nutrition',
      builder: (context, state) {
        final mealPlanId = state.pathParameters['id']!;
        return MealPlanNutritionScreen(mealPlanId: mealPlanId);
      },
    ),

    // =========================================================
    // WEIGHT LOSS
    // =========================================================
    GoRoute(
      path: '/weight-loss',
      builder: (context, state) => const WeightLossScreen(),
    ),

    // =========================================================
    // COMMUNITY
    // =========================================================
    GoRoute(
      path: '/community',
      builder: (context, state) => const CommunityScreen(),
    ),

    GoRoute(
      path: '/community/create',
      builder: (context, state) => const CreateCommunityPostScreen(),
    ),

    GoRoute(
      path: '/community/posts/:id',
      builder: (context, state) {
        final postId = state.pathParameters['id']!;
        return CommunityPostDetailScreen(postId: postId);
      },
    ),

    // =========================================================
    // RECIPE DETAIL
    // =========================================================
    GoRoute(
      path: '/recipe/:id',
      builder: (context, state) {
        final recipeId = state.pathParameters['id']!;
        return RecipeDetailScreen(recipeId: recipeId);
      },
    ),
  ],
);
