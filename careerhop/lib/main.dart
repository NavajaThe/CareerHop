import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // For loading .env variables
import 'package:supabase_flutter/supabase_flutter.dart'; // For Supabase integration
import 'package:go_router/go_router.dart';          // Import go_router
import 'package:flutter_web_plugins/url_strategy.dart'; // Import for URL strategy

// Placeholder for your AppConfig if it's in a separate file
// Ensure this class or mechanism provides the Supabase URL and Anon Key
class AppConfig {
  // Replace with your actual Supabase URL and Anon Key retrieval logic
  // Often loaded from .env
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? 'YOUR_SUPABASE_URL_FALLBACK';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? 'YOUR_SUPABASE_ANON_KEY_FALLBACK';
}


// Supabase client instance
final supabase = Supabase.instance.client;

// --- Define Your Routes ---
// It's good practice to define routes in a separate file, but for simplicity,
// we'll define them here initially.

// Define simple placeholder screen widgets
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home Screen')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             const Text('Welcome to the Home Screen!'),
             ElevatedButton(
                // Example navigation
                onPressed: () => context.go('/details/123'),
                child: const Text('Go to Details Page (ID: 123)'),
             ),
             const SizedBox(height: 20),
             ElevatedButton(
                onPressed: () => context.go('/unknown'), // Example of a non-existent route
                child: const Text('Go to Unknown Page'),
             ),
          ],
        ),
      ),
    );
  }
}

class DetailsScreen extends StatelessWidget {
  final String id;
  const DetailsScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Details Screen (ID: $id)')),
      body: Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Showing details for ID: $id'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => context.go('/'), // Go back home
                child: const Text('Go Back Home'),
              ),
            ],
        ),
      ),
    );
  }
}

// Simple error screen for unknown routes
class ErrorScreen extends StatelessWidget {
  final Exception? error;
  const ErrorScreen({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Oops! Something went wrong or the page doesn\'t exist.'),
            if (error != null) SelectableText(error.toString()),
             const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => context.go('/'), // Go back home
                child: const Text('Go Back Home'),
              ),
          ],
        ),
      ),
    );
  }
}


// --- Configure GoRouter ---
final GoRouter _router = GoRouter(
  initialLocation: '/', // Set the initial route
  errorBuilder: (context, state) => ErrorScreen(error: state.error), // Handle errors/unknown routes
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const HomeScreen();
      },
      routes: <RouteBase>[ // Example of nested routes if needed
        GoRoute(
          path: 'details/:id', // Use :id for path parameters
          builder: (BuildContext context, GoRouterState state) {
            // Extract the 'id' parameter from the route state
            final String id = state.pathParameters['id'] ?? 'unknown';
            return DetailsScreen(id: id);
          },
        ),
      ],
    ),
    // Add other top-level routes here
    // e.g., /login, /settings etc.
    // GoRoute(
    //   path: '/login',
    //   builder: (context, state) => const LoginScreen(),
    // ),
  ],
  // Optional: Add observers for tracking navigation, e.g., for analytics
  // observers: [ ... ],
  // Optional: Add redirection logic (e.g., redirect to login if not authenticated)
  // redirect: (BuildContext context, GoRouterState state) {
  //   // Add your authentication check logic here
  //   final bool loggedIn = ... ; // Check auth state (e.g., via Supabase)
  //   final bool loggingIn = state.matchedLocation == '/login';
  //   if (!loggedIn && !loggingIn) return '/login'; // Redirect to login if not logged in and not already on login page
  //   if (loggedIn && loggingIn) return '/'; // Redirect to home if logged in and on login page
  //   return null; // No redirect needed
  // },
);


// --- Main Application Entry Point ---
Future<void> main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Use PathUrlStrategy for cleaner web URLs (removes the #)
  // Call this BEFORE `runApp`
  setUrlStrategy(PathUrlStrategy());

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
    debugPrint('.env file loaded successfully.');
  } catch (e) {
    // Handle error if .env file is missing or cannot be loaded
    debugPrint('WARNING: Could not load .env file: $e. Using fallback or default values.');
    // Depending on your app's needs, this might be a critical error or recoverable
  }

  // Initialize Supabase
  try {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
    debugPrint('Supabase initialized successfully.');
  } catch (e) {
      debugPrint('FATAL ERROR: Supabase initialization failed: $e');
      // Consider showing an error message to the user or stopping the app gracefully
      return; // Exit if Supabase fails
  }

  // Run the app
  runApp(const MyApp());
}

// --- Root Application Widget ---
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Use MaterialApp.router to integrate GoRouter
    return MaterialApp.router(
      title: 'Flutter Web App with GoRouter', // Set your app title
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // Provide the GoRouter configuration
      routerConfig: _router,
      debugShowCheckedModeBanner: false, // Optional: hide debug banner
    );
  }
}