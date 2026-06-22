import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'changelog_models.dart';

final List<ChangelogVersion> changelogVersions = [
  ChangelogVersion(
    version: '2.3.0',
    tagline: 'The Journey Continues',
    description:
        'Chapter 2 is finally here, along with major updates to Field Day and subtle mysteries to discover.',
    features: [
      ChangelogFeature(
        icon: HugeIcons.strokeRoundedBookOpen01,
        title: 'Chapter 2: The Open Shore',
        description:
            'Traverse the Open Shore and prepare for the crossing. The story continues.',
        color: const Color(0xFF3B82F6),
      ),
      ChangelogFeature(
        icon: HugeIcons.strokeRoundedCalendar03,
        title: 'Field Day Focus',
        description:
            'Fully implemented the BCA Field Day screen and events widget with custom scheduling.',
        color: const Color(0xFF10B981),
      ),
      ChangelogFeature(
        icon: HugeIcons.strokeRoundedLockPassword,
        title: 'Security Patches',
        description:
            'Fixed minor stability and session token bugs in the Firebase Authentication system.',
        color: const Color(0xFFF59E0B),
      ),
      ChangelogFeature(
        icon: HugeIcons.strokeRoundedSparkles,
        title: 'Deep Waters',
        description:
            'Pay close attention to the deep waters. They say there are seven hidden orange fishes circling the Unnamed Tree...',
        color: const Color(0xFFEC4899),
      ),
    ],
  ),
  ChangelogVersion(
    version: '2.2.0',
    tagline: 'The Half Anniversary Update',
    description:
        'A major milestone update bringing reliable automation, new choices, and deeper mysteries.',
    features: [
      ChangelogFeature(
        icon: HugeIcons.strokeRoundedServerStack03,
        title: 'Meet Junior',
        description:
            'Say hello to Junior! Our new automated system tirelessly runs the bus and teacher scripts in the background so you\'re always up to date.',
        color: const Color(0xFF6366F1),
      ),
      ChangelogFeature(
        icon: HugeIcons.strokeRoundedNotification03,
        title: 'Reliable Notifications',
        description:
            'A completely revamped notification system. Fun, creative, and guaranteed to alert you whenever a bus or teacher status changes.',
        color: const Color(0xFF10B981),
      ),
      ChangelogFeature(
        icon: HugeIcons.strokeRoundedSparkles,
        title: 'Fun & Serious Modes',
        description:
            'Keep Fun Mode off by default for a clean experience. The Gr0ve story unlocks only after completing the changelog Easter egg, then the hidden narrative becomes available.',
        color: const Color(0xFFF59E0B),
      ),
      ChangelogFeature(
        icon: HugeIcons.strokeRoundedBookOpen01,
        title: 'The Seed is Planted',
        description:
            'The soil shifts. Roots grow deeper into the dark. What was buried will not stay hidden forever. Are you ready to fly?',
        color: const Color(0xFFEC4899),
      ),
    ],
  ),
  ChangelogVersion(
    version: '2.1.0',
    tagline: 'Refined controls & recognition.',
    description:
        'Focusing on smoothing out the admin experience and giving credit where it\'s due.',
    features: [
      ChangelogFeature(
        icon: HugeIcons.strokeRoundedSettings01,
        title: 'Admin Excellence',
        description:
            'New ultra-compact, reactive grid system for managing teacher absences with ease.',
        color: const Color(0xFF6366F1),
      ),
      ChangelogFeature(
        icon: HugeIcons.strokeRoundedUserGroup,
        title: 'Detailed Credits',
        description:
            'A brand new credits page to recognize the icon designers and dedicated testers.',
        color: const Color(0xFFEC4899),
      ),
      ChangelogFeature(
        icon: HugeIcons.strokeRoundedLockPassword,
        title: 'Locked Personas',
        description:
            'Hidden counselor personas are now strictly gated for a more rewarding discovery experience. They\'re protected by the Almighty Grove Keeper.',
        color: const Color(0xFFF59E0B),
      ),
      ChangelogFeature(
        icon: HugeIcons.strokeRoundedDeveloper,
        title: 'iOS Stability',
        description:
            'Crucial under-the-hood fixes to ensure gr0ve remains rock-solid on all Apple devices.',
        color: const Color(0xFF10B981),
      ),
    ],
  ),
  ChangelogVersion(
    version: '2.0.0',
    tagline: 'A whole new look & feel.',
    description:
        'We\'ve completely redesigned the entire app to make it faster, smoother, and more beautiful than ever.',
    features: [
      ChangelogFeature(
        icon: HugeIcons.strokeRoundedTime03,
        title: 'Time-Adaptive Home',
        description:
            'Your dashboard now automatically adapts its layout based on the time of day: morning, school hours, and evening.',
        color: const Color(0xFF3B82F6),
      ),
      ChangelogFeature(
        icon: HugeIcons.strokeRoundedGridView,
        title: 'Customizable Navigation',
        description:
            'Reorder and hide navigation tabs to create a personalized experience that perfectly fits your daily needs.',
        color: const Color(0xFF8B5CF6),
      ),
      ChangelogFeature(
        icon: HugeIcons.strokeRoundedCalendar03,
        title: 'All-New Calendar',
        description:
            'A completely rebuilt calendar page to track your schedule, events, and assignments effortlessly in one place.',
        color: const Color(0xFFEF4444),
      ),
      ChangelogFeature(
        icon: HugeIcons.strokeRoundedUserCircle,
        title: 'Profile Pictures & More',
        description:
            'Personalize your account with expressive avatars. Who knows? You might even discover some hidden characters.',
        color: const Color(0xFF14B8A6),
      ),
    ],
  ),
  ChangelogVersion(
    version: '1.4.5',
    tagline: 'Maintenance & Polish',
    description:
        'Sadly, a minor bug was discoverd with the bus refreshing system, that has successfully been patched. Also minor restyling in calendar and help pages.',
    features: [],
  ),
  ChangelogVersion(
    version: '1.4.4',
    tagline: 'Style & Refinement',
    description:
        'After much demand, we restyled the app, making it easier to use. Also made some minor patches to enahnce the overall experience.',
    features: [],
  ),
  ChangelogVersion(
    version: '1.4.3',
    tagline: 'Smart Notifications',
    description:
        'This update brings intelligent bus arrival notifications: get notified when your starred buses arrive, with automatic detection of minimum days and regular dismissal times.',
    features: [],
  ),
  ChangelogVersion(
    version: '1.4.0',
    tagline: 'Events & Links',
    description:
        'Added a calendar page to view BCA events and add your own personal events. Improved quick links with edit and reorder functionality.',
    features: [],
  ),
  ChangelogVersion(
    version: '1.3.0',
    tagline: 'Performance & Lunch',
    description:
        'Improved auto-refresh behavior across the app. Introducing the brand-new Lunch page with today\'s menu and nutrition facts.',
    features: [],
  ),
  ChangelogVersion(
    version: '1.2.1',
    tagline: 'Quick Fix',
    description:
        'Apologies for the last update! An unexpected error occured when users attempted to add a link. Thankfully, that problem is fully patched.',
    features: [],
  ),
  ChangelogVersion(
    version: '1.2.0',
    tagline: 'Security & Management',
    description:
        'Completely overhauled the login system with an updated backend for faster and more secure sign-ins. Plus, brand-new Quick Links management.',
    features: [],
  ),
  ChangelogVersion(
    version: '1.1.3',
    tagline: 'API Maintenance',
    description:
        'Made a small patch to update the constant loading issue stemmed from the API for the Bus Location google sheet.',
    features: [],
  ),
  ChangelogVersion(
    version: '1.1.2',
    tagline: 'Cross-Platform Polish',
    description:
        'Restyled the landing page and fixed phone and web compatibility issues with fetching.',
    features: [],
  ),
  ChangelogVersion(
    version: '1.1.1',
    tagline: 'Matching & Display',
    description:
        'Added a homepage and fixed edge cases with teacher and bus names to ensure proper matching and display.',
    features: [],
  ),
  ChangelogVersion(
    version: '1.0.1',
    tagline: 'Favorites',
    description:
        'Introduced starring! You can now star your favorite buses and teachers to keep them at the top of your lists.',
    features: [],
  ),
  ChangelogVersion(
    version: '1.0.0',
    tagline: 'The Dawn',
    description:
        'Gr0ve\'s first public release! Track live bus parking locations, view teacher absences, and access essential school resources.',
    features: [],
  ),
];
