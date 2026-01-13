import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/agency_registration_screen.dart';
import '../screens/auth/admin_login_screen.dart';
import '../screens/traveler/traveler_shell.dart';
import '../screens/traveler/home_screen.dart';
import '../screens/traveler/search_screen.dart';
import '../screens/traveler/my_bookings_screen.dart';
import '../screens/traveler/tour_detail_screen.dart';
import '../screens/traveler/profile_screen.dart';
import '../screens/traveler/edit_profile_screen.dart';
import '../screens/traveler/agency_profile_screen.dart';
import '../screens/traveler/live_track_screen.dart';
import '../screens/traveler/booking_ticket_screen.dart';
import '../screens/traveler/payment_screen.dart';
import '../screens/traveler/chatbot_screen.dart';
import '../screens/traveler/dummy_payment_screen.dart';
import '../screens/traveler/notifications_screen.dart';
import '../screens/traveler/help_support_screen.dart';
import '../screens/traveler/about_screen.dart';
import '../screens/traveler/write_review_screen.dart';
import '../screens/traveler/my_reviews_screen.dart';
import '../screens/traveler/success_story_screen.dart';
import '../../models/review_model.dart';
import '../../models/booking_model.dart';
import '../screens/agency/agency_shell.dart';
import '../screens/agency/agency_dashboard.dart';
import '../screens/agency/agency_tours_screen.dart';
import '../screens/agency/agency_bookings_screen.dart';
import '../screens/agency/create_tour_screen.dart';
import '../screens/agency/verification_pending_screen.dart';
import '../screens/agency/agency_settings_screen.dart';
import '../screens/agency/live_tour_console_screen.dart';
import '../screens/admin/admin_shell.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/admin/agency_management_screen.dart';
import '../screens/admin/admin_tours_screen.dart';
import '../screens/admin/admin_settings_screen.dart';
import '../screens/admin/terms_of_service_screen.dart';
import '../screens/admin/privacy_policy_screen.dart';
import '../screens/chat/chats_list_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/agency/agency_reviews_screen.dart';
import '../screens/admin/admin_reviews_screen.dart';
import '../screens/admin/review_moderation_screen.dart';
import '../screens/notification_list_screen.dart';
import '../screens/public/ticket_verification_screen.dart';
import '../screens/splash_screen.dart';

class AppRouter {
  static GoRouter? _router;

  static GoRouter router(AuthProvider authProvider) {
    _router ??= GoRouter(
      refreshListenable: authProvider,
      initialLocation: '/splash',
      redirect: (context, state) {
        final currentPath = state.matchedLocation;

        // Splash route - always allow access to show animation
        if (currentPath == '/splash') {
          return null;
        }

        final isAuthRoute =
            currentPath == '/login' ||
            currentPath == '/signup' ||
            currentPath == '/admin/login';

        // Admin routes - NO FIREBASE CHECK, just allow access
        if (currentPath.startsWith('/admin/')) {
          return null;
        }

        // Public routes - No auth check
        if (currentPath.startsWith('/verify-ticket')) {
          return null;
        }

        // For non-admin routes, use Firebase authentication
        final user = authProvider.user;
        final isLoggedIn = user != null;

        // If not logged in and trying to access protected route
        if (!isLoggedIn && !isAuthRoute) {
          return '/login';
        }

        // If not logged in, allow auth routes
        if (!isLoggedIn) {
          return null;
        }

        // From here on, user is logged in
        if (isAuthRoute) {
          final homeRoute = _getHomeRoute(user);
          debugPrint(
            'Router redirect: User on auth route ($currentPath), redirecting to: $homeRoute',
          );
          return homeRoute;
        }

        // Agency verification check
        if (user.role == UserRole.agency) {
          final isProfileComplete =
              user.businessLicenseNumber != null && user.phone != null;

          if (!isProfileComplete) {
            if (currentPath != '/agency/registration') {
              debugPrint(
                'Router redirect: Agency profile incomplete, redirecting to registration',
              );
              return '/agency/registration';
            }
          } else {
            if (!user.verified ||
                user.status == VerificationStatus.pending ||
                user.status == VerificationStatus.rejected) {
              if (!currentPath.startsWith('/agency/verification')) {
                debugPrint(
                  'Router redirect: Agency not verified, redirecting to verification',
                );
                return '/agency/verification';
              }
            }
          }
        }

        // Guard agency routes
        if (currentPath.startsWith('/agency/')) {
          if (user.role != UserRole.agency) {
            final homeRoute = _getHomeRoute(user);
            return homeRoute;
          }
          return null;
        }

        // Guard traveler routes
        if (currentPath.startsWith('/traveler/') ||
            currentPath.startsWith('/chat/') ||
            currentPath.startsWith('/chatbot') ||
            currentPath.startsWith('/ticket/') ||
            currentPath.startsWith('/live-track/') ||
            currentPath.startsWith('/payment/') ||
            currentPath.startsWith('/dummy-payment/') ||
            currentPath.startsWith('/agency-profile/')) {
          if (user.role == UserRole.admin) {
            if (currentPath.startsWith('/chat/') ||
                currentPath.startsWith('/agency-profile/') ||
                currentPath.startsWith('/live-track/') ||
                currentPath.startsWith('/ticket/')) {
              return null;
            }
            return '/admin/dashboard';
          }
          return null;
        }

        return _getHomeRoute(user);
      },
      routes: [
        GoRoute(
          path: '/login',
          pageBuilder: (context, state) =>
              _fadePage(state, const LoginScreen()),
        ),
        GoRoute(
          path: '/splash',
          pageBuilder: (context, state) =>
              _fadePage(state, const ProfessionalSplashScreen()),
        ),
        GoRoute(
          path: '/signup',
          pageBuilder: (context, state) =>
              _fadePage(state, const SignupScreen()),
        ),
        GoRoute(
          path: '/agency/registration',
          pageBuilder: (context, state) =>
              _fadePage(state, const AgencyRegistrationScreen()),
        ),
        GoRoute(
          path: '/admin/login',
          pageBuilder: (context, state) =>
              _fadePage(state, const AdminLoginScreen()),
        ),
        ShellRoute(
          pageBuilder: (context, state, child) =>
              _fadePage(state, TravelerShell(child: child)),
          routes: [
            GoRoute(
              path: '/traveler/home',
              pageBuilder: (context, state) =>
                  _fadePage(state, const HomeScreen()),
            ),
            GoRoute(
              path: '/traveler/search',
              pageBuilder: (context, state) =>
                  _fadePage(state, const SearchScreen()),
            ),
            GoRoute(
              path: '/traveler/bookings',
              pageBuilder: (context, state) {
                final tabParam = state.uri.queryParameters['tab'];
                final initialTab = int.tryParse(tabParam ?? '0') ?? 0;
                return _fadePage(
                  state,
                  MyBookingsScreen(initialTab: initialTab),
                );
              },
            ),
            GoRoute(
              path: '/traveler/chats',
              pageBuilder: (context, state) =>
                  _fadePage(state, const ChatsListScreen()),
            ),
            GoRoute(
              path: '/traveler/profile',
              pageBuilder: (context, state) =>
                  _fadePage(state, const ProfileScreen()),
            ),
            GoRoute(
              path: '/traveler/profile/edit',
              pageBuilder: (context, state) =>
                  _fadePage(state, const EditProfileScreen()),
            ),
            GoRoute(
              path: '/traveler/profile/notifications',
              pageBuilder: (context, state) =>
                  _fadePage(state, const NotificationsScreen()),
            ),
            GoRoute(
              path: '/traveler/profile/help',
              pageBuilder: (context, state) =>
                  _fadePage(state, const HelpSupportScreen()),
            ),
            GoRoute(
              path: '/traveler/profile/about',
              pageBuilder: (context, state) =>
                  _fadePage(state, const AboutScreen()),
            ),
            GoRoute(
              path: '/traveler/review',
              pageBuilder: (context, state) {
                final extra = state.extra as Map<String, dynamic>;
                return _fadePage(
                  state,
                  WriteReviewScreen(
                    booking: extra['booking'] as BookingModel,
                    tourTitle: extra['tourTitle'] as String,
                  ),
                );
              },
            ),
            GoRoute(
              path: '/traveler/notifications',
              pageBuilder: (context, state) =>
                  _fadePage(state, const NotificationListScreen()),
            ),
            GoRoute(
              path: '/traveler/success-story/:reviewId',
              pageBuilder: (context, state) {
                final reviewId = state.pathParameters['reviewId']!;
                final review = state.extra as ReviewModel?;
                return _fadePage(
                  state,
                  SuccessStoryScreen(reviewId: reviewId, initialReview: review),
                );
              },
            ),
            GoRoute(
              path: '/traveler/my-reviews',
              pageBuilder: (context, state) =>
                  _fadePage(state, const MyReviewsScreen()),
            ),
          ],
        ),
        GoRoute(
          path: '/traveler/tour/:id',
          pageBuilder: (context, state) => _fadePage(
            state,
            TourDetailScreen(tourId: state.pathParameters['id']!),
          ),
        ),
        GoRoute(
          path: '/agency-profile/:id',
          pageBuilder: (context, state) => _fadePage(
            state,
            AgencyProfileScreen(agencyId: state.pathParameters['id']!),
          ),
        ),
        GoRoute(
          path: '/live-track/:tourId',
          pageBuilder: (context, state) => _fadePage(
            state,
            LiveTrackScreen(tourId: state.pathParameters['tourId']!),
          ),
        ),
        GoRoute(
          path: '/ticket/:bookingId',
          pageBuilder: (context, state) => _fadePage(
            state,
            BookingTicketScreen(bookingId: state.pathParameters['bookingId']!),
          ),
        ),
        GoRoute(
          path: '/payment/:bookingId',
          pageBuilder: (context, state) => _fadePage(
            state,
            PaymentScreen(bookingId: state.pathParameters['bookingId']!),
          ),
        ),
        GoRoute(
          path: '/chat/:chatId',
          pageBuilder: (context, state) => _fadePage(
            state,
            ChatScreen(chatId: state.pathParameters['chatId']!),
          ),
        ),
        GoRoute(
          path: '/chatbot',
          pageBuilder: (context, state) =>
              _fadePage(state, const ChatbotScreen()),
        ),
        GoRoute(
          path: '/dummy-payment/:bookingId',
          pageBuilder: (context, state) => _fadePage(
            state,
            DummyPaymentScreen(bookingId: state.pathParameters['bookingId']!),
          ),
        ),
        GoRoute(
          path: '/agency/verification',
          pageBuilder: (context, state) =>
              _fadePage(state, const VerificationPendingScreen()),
        ),
        ShellRoute(
          pageBuilder: (context, state, child) =>
              _fadePage(state, AgencyShell(child: child)),
          routes: [
            GoRoute(
              path: '/agency/dashboard',
              pageBuilder: (context, state) =>
                  _fadePage(state, const AgencyDashboard()),
            ),
            GoRoute(
              path: '/agency/tours',
              pageBuilder: (context, state) =>
                  _fadePage(state, const AgencyToursScreen()),
            ),
            GoRoute(
              path: '/agency/bookings',
              pageBuilder: (context, state) =>
                  _fadePage(state, const AgencyBookingsScreen()),
            ),
            GoRoute(
              path: '/agency/chats',
              pageBuilder: (context, state) =>
                  _fadePage(state, const ChatsListScreen()),
            ),
            GoRoute(
              path: '/agency/settings',
              pageBuilder: (context, state) =>
                  _fadePage(state, const AgencySettingsScreen()),
            ),
            GoRoute(
              path: '/agency/reviews',
              pageBuilder: (context, state) =>
                  _fadePage(state, const AgencyReviewsScreen()),
            ),
          ],
        ),
        GoRoute(
          path: '/agency/tours/create',
          pageBuilder: (context, state) =>
              _fadePage(state, const CreateTourScreen()),
        ),
        GoRoute(
          path: '/agency/tours/edit/:id',
          pageBuilder: (context, state) => _fadePage(
            state,
            CreateTourScreen(tourId: state.pathParameters['id']),
          ),
        ),
        GoRoute(
          path: '/agency/notifications',
          pageBuilder: (context, state) =>
              _fadePage(state, const NotificationListScreen()),
        ),
        GoRoute(
          path: '/agency/live-console/:id',
          pageBuilder: (context, state) {
            final tourId = state.pathParameters['id']!;
            final tourTitle = state.extra as String? ?? 'Active Tour';
            return _fadePage(
              state,
              LiveTourConsoleScreen(tourId: tourId, tourTitle: tourTitle),
            );
          },
        ),
        ShellRoute(
          pageBuilder: (context, state, child) =>
              _fadePage(state, AdminShell(child: child)),
          routes: [
            GoRoute(
              path: '/admin/dashboard',
              pageBuilder: (context, state) =>
                  _fadePage(state, const AdminDashboard()),
            ),
            GoRoute(
              path: '/admin/agencies',
              pageBuilder: (context, state) =>
                  _fadePage(state, const AgencyManagementScreen()),
            ),
            GoRoute(
              path: '/admin/tours',
              pageBuilder: (context, state) =>
                  _fadePage(state, const AdminToursScreen()),
            ),
            GoRoute(
              path: '/admin/settings',
              pageBuilder: (context, state) =>
                  _fadePage(state, const AdminSettingsScreen()),
            ),
            GoRoute(
              path: '/admin/tour/:id',
              pageBuilder: (context, state) => _fadePage(
                state,
                TourDetailScreen(tourId: state.pathParameters['id']!),
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/admin/reviews',
          pageBuilder: (context, state) =>
              _fadePage(state, const AdminReviewsScreen()),
        ),
        GoRoute(
          path: '/admin/users',
          pageBuilder: (context, state) =>
              _fadePage(state, const TermsOfServiceScreen()),
        ),
        GoRoute(
          path: '/admin/review-moderation',
          pageBuilder: (context, state) =>
              _fadePage(state, const ReviewModerationScreen()),
        ),
        GoRoute(
          path: '/admin/terms',
          pageBuilder: (context, state) =>
              _fadePage(state, const TermsOfServiceScreen()),
        ),
        GoRoute(
          path: '/admin/privacy',
          pageBuilder: (context, state) =>
              _fadePage(state, const PrivacyPolicyScreen()),
        ),
        GoRoute(
          path: '/admin/chats',
          pageBuilder: (context, state) =>
              _fadePage(state, const ChatsListScreen()),
        ),
        GoRoute(
          path: '/verify-ticket',
          pageBuilder: (context, state) {
            final bookingId = state.uri.queryParameters['id'];
            if (bookingId == null || bookingId.isEmpty) {
              return _fadePage(
                state,
                Scaffold(
                  appBar: AppBar(title: const Text('Error')),
                  body: const Center(child: Text('Invalid ticket ID')),
                ),
              );
            }
            return _fadePage(
              state,
              TicketVerificationScreen(bookingId: bookingId),
            );
          },
        ),
      ],
    );
    return _router!;
  }

  static CustomTransitionPage _fadePage(GoRouterState state, Widget child) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
          child: child,
        );
      },
    );
  }

  static String _getHomeRoute(UserModel user) {
    // Handle role-based routing with proper checks
    debugPrint(
      '_getHomeRoute called with role: ${user.role.name}, verified: ${user.verified}, status: ${user.status.name}',
    );

    switch (user.role) {
      case UserRole.admin:
        if (!user.verified || user.status != VerificationStatus.verified) {
          // Admin account not verified - shouldn't happen but handle gracefully
          debugPrint('Admin not verified, redirecting to admin login');
          return '/admin/login';
        }
        debugPrint('Returning admin dashboard');
        return '/admin/dashboard';
      case UserRole.agency:
        // Check profile completeness first
        if (user.businessLicenseNumber == null) {
          return '/agency/registration';
        }

        if (!user.verified ||
            user.status == VerificationStatus.pending ||
            user.status == VerificationStatus.rejected) {
          debugPrint(
            'Agency not verified/pending/rejected, redirecting to verification',
          );
          return '/agency/verification';
        }
        debugPrint('Returning agency dashboard');
        return '/agency/dashboard';
      case UserRole.traveler:
        debugPrint('Returning traveler home');
        return '/traveler/home';
    }
  }
}
