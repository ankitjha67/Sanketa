import 'package:flutter/material.dart';
import 'package:sanketa_design/sanketa_design.dart';

import '../control/remote_controller.dart';
import '../theme/tokens_x.dart';
import '../widgets/common.dart';
import 'app_launcher_screen.dart';
import 'backup_screen.dart';
import 'connection_doctor_screen.dart';
import 'custom_layout_screen.dart';
import 'debloat_screen.dart';
import 'activity_history_screen.dart';
import 'favourite_channels_screen.dart';
import 'gesture_shortcuts_screen.dart';
import 'hdmi_manager_screen.dart';
import 'macro_screen.dart';
import 'multi_room_screen.dart';
import 'network_diagnostics_screen.dart';
import 'parental_controls_screen.dart';
import 'quick_text_screen.dart';
import 'remote_profiles_screen.dart';
import 'night_mode_screen.dart';
import 'button_mapper_screen.dart';
import 'cec_devices_screen.dart';
import 'universal_search_screen.dart';
import 'remote_lock_screen.dart';
import 'picture_settings_screen.dart';
import 'sound_settings_screen.dart';
import 'qr_share_screen.dart';
import 'game_pad_screen.dart';
import 'ambient_display_screen.dart';
import 'subtitle_manager_screen.dart';
import 'quick_dashboard_screen.dart';
import 'motion_control_screen.dart';
import 'channel_guide_screen.dart';
import 'parental_timer_screen.dart';
import 'accessibility_screen.dart';
import 'remote_themes_screen.dart';
import 'volume_limiter_screen.dart';
import 'wake_on_lan_screen.dart';
import 'quick_dial_screen.dart';
import 'media_info_screen.dart';
import 'screen_timeout_screen.dart';
import 'energy_monitor_screen.dart';
import 'ir_learning_screen.dart';
import 'sleep_sounds_screen.dart';
import 'multi_tv_screen.dart';
import 'input_rename_screen.dart';
import 'diagnostic_log_screen.dart';
import 'colour_test_screen.dart';
import 'child_profile_screen.dart';
import 'network_info_screen.dart';
import 'tv_app_manager_screen.dart';
import 'remote_clipboard_screen.dart';
import 'whistle_finder_screen.dart';
import 'firmware_info_screen.dart';
import 'notification_manager_screen.dart';
import 'speed_test_screen.dart';
import 'power_schedule_screen.dart';
import 'aspect_ratio_screen.dart';
import 'mouse_cursor_screen.dart';
import 'floating_remote_screen.dart';
import 'tv_screenshot_screen.dart';
import 'cast_queue_screen.dart';
import 'connection_pulse_screen.dart';
import 'rooms_screen.dart';
import 'scheduled_actions_screen.dart';
import 'screen_mirror_screen.dart';
import 'search_shortcuts_screen.dart';
import 'touchpad_screen.dart';
import 'tv_stats_screen.dart';
import 'usage_analytics_screen.dart';
import 'video_handoff_screen.dart';
import 'voice_screen.dart';
import 'wearable_screen.dart';
import 'widget_config_screen.dart';
import 'deep_link_screen.dart';
import 'wakelock_screen.dart';
import 'audio_output_screen.dart';
import 'qr_connect_screen.dart';
import 'text_templates_screen.dart';
import 'haptic_feedback_screen.dart';
import 'device_info_screen.dart';
import 'auto_scroll_screen.dart';
import 'screen_saver_screen.dart';
import 'quick_settings_screen.dart';
import 'tv_notifications_screen.dart';
import 'keyboard_layouts_screen.dart';
import 'voice_commands_screen.dart';
import 'multi_device_screen.dart';
import 'photo_cast_screen.dart';
import 'tv_alarm_screen.dart';
import 'quick_notes_screen.dart';
import 'remote_sharing_screen.dart';
import 'swipe_remote_screen.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _header(),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 448),
              child: GridView.count(
                crossAxisCount: 2,
                padding: const EdgeInsets.all(AppSpacing.lg),
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: 1.1,
                children: [
                  _ToolCard(
                    icon: Icons.cleaning_services_rounded,
                    title: 'TV Debloat',
                    subtitle: 'Remove ads & bloatware',
                    color: AppColors.error,
                    onTap: () => _push(context, const DebloatScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.analytics_rounded,
                    title: 'TV Stats',
                    subtitle: 'Performance dashboard',
                    color: AppColors.tertiary,
                    onTap: () => _push(context, const TvStatsScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.apps_rounded,
                    title: 'App Launcher',
                    subtitle: 'Launch & manage TV apps',
                    color: AppColors.secondary,
                    onTap: () => _push(context, const AppLauncherScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.healing_rounded,
                    title: 'Doctor',
                    subtitle: 'Diagnose connections',
                    color: AppColors.primary,
                    onTap: () => _push(context, const ConnectionDoctorScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.play_circle_outline_rounded,
                    title: 'Macros',
                    subtitle: 'Automate TV routines',
                    color: AppColors.primaryContainer,
                    onTap: () => _push(context, const MacroScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.bookmark_rounded,
                    title: 'Shortcuts',
                    subtitle: 'Saved search queries',
                    color: AppColors.tertiary,
                    onTap: () => _push(context, const SearchShortcutsScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.dashboard_customize_rounded,
                    title: 'Layouts',
                    subtitle: 'Custom remote grids',
                    color: AppColors.secondary,
                    onTap: () => _push(context, const CustomLayoutScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.shield_rounded,
                    title: 'Parental',
                    subtitle: 'PIN lock & key blocking',
                    color: AppColors.error,
                    onTap: () => _push(context, const ParentalControlsScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.devices_rounded,
                    title: 'Multi-Room',
                    subtitle: 'Control all TVs',
                    color: AppColors.signalEmerald,
                    onTap: () => _push(context, const MultiRoomScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.mic_rounded,
                    title: 'Voice',
                    subtitle: 'Speak to type on TV',
                    color: AppColors.primary,
                    onTap: () => _push(context, const VoiceScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.touch_app_rounded,
                    title: 'Touchpad',
                    subtitle: 'Full-screen touchpad',
                    color: AppColors.tertiary,
                    onTap: () => _push(context, const TouchpadScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.wifi_find_rounded,
                    title: 'Network',
                    subtitle: 'Diagnose connectivity',
                    color: AppColors.primaryContainer,
                    onTap: () => _push(context, const NetworkDiagnosticsScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.bar_chart_rounded,
                    title: 'Usage',
                    subtitle: 'TV usage analytics',
                    color: AppColors.signalEmerald,
                    onTap: () => _push(context, const UsageAnalyticsScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.cast_connected_rounded,
                    title: 'Mirror',
                    subtitle: 'Cast phone screen',
                    color: AppColors.secondary,
                    onTap: () => _push(context, const ScreenMirrorScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.backup_rounded,
                    title: 'Backup',
                    subtitle: 'Save & restore data',
                    color: AppColors.tertiary,
                    onTap: () => _push(context, const BackupScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.widgets_rounded,
                    title: 'Widgets',
                    subtitle: 'Home screen controls',
                    color: AppColors.primary,
                    onTap: () => _push(context, const WidgetConfigScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.watch_rounded,
                    title: 'Wearable',
                    subtitle: 'Watch remote control',
                    color: AppColors.signalEmerald,
                    onTap: () => _push(context, const WearableScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.ondemand_video_rounded,
                    title: 'Video',
                    subtitle: 'Send URLs to TV',
                    color: AppColors.error,
                    onTap: () => _push(context, const VideoHandoffScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.meeting_room_rounded,
                    title: 'Rooms',
                    subtitle: 'Organize by room',
                    color: AppColors.primaryContainer,
                    onTap: () => _push(context, const RoomsScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.star_rounded,
                    title: 'Favourites',
                    subtitle: 'Quick channel access',
                    color: AppColors.signalEmerald,
                    onTap: () => _push(context, const FavouriteChannelsScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.gesture,
                    title: 'Gestures',
                    subtitle: 'Phone motion shortcuts',
                    color: AppColors.tertiary,
                    onTap: () => _push(context, const GestureShortcutsScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.schedule_rounded,
                    title: 'Schedules',
                    subtitle: 'Timed TV actions',
                    color: AppColors.secondary,
                    onTap: () => _push(context, const ScheduledActionsScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.text_snippet_rounded,
                    title: 'Quick Text',
                    subtitle: 'Saved text templates',
                    color: AppColors.primary,
                    onTap: () => _push(context, const QuickTextScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.settings_input_hdmi_rounded,
                    title: 'HDMI',
                    subtitle: 'Name & switch inputs',
                    color: AppColors.error,
                    onTap: () => _push(context, const HdmiManagerScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.history_rounded,
                    title: 'History',
                    subtitle: 'Command activity log',
                    color: AppColors.primaryContainer,
                    onTap: () => _push(context, const ActivityHistoryScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.people_rounded,
                    title: 'Profiles',
                    subtitle: 'Per-user remote settings',
                    color: AppColors.signalEmerald,
                    onTap: () => _push(context, const RemoteProfilesScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.bedtime_rounded,
                    title: 'Night Mode',
                    subtitle: 'Evening volume & display',
                    color: AppColors.tertiary,
                    onTap: () => _push(context, const NightModeScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.tune_rounded,
                    title: 'Buttons',
                    subtitle: 'Remap hardware keys',
                    color: AppColors.secondary,
                    onTap: () => _push(context, const ButtonMapperScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.settings_input_hdmi_rounded,
                    title: 'CEC',
                    subtitle: 'HDMI-CEC device control',
                    color: AppColors.primary,
                    onTap: () => _push(context, const CecDevicesScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.search_rounded,
                    title: 'Search',
                    subtitle: 'Universal TV search',
                    color: AppColors.error,
                    onTap: () => _push(context, const UniversalSearchScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.lock,
                    title: 'Lock',
                    subtitle: 'Prevent accidental presses',
                    color: AppColors.error,
                    onTap: () => _push(context, const RemoteLockScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.photo_filter,
                    title: 'Picture',
                    subtitle: 'TV picture presets',
                    color: AppColors.tertiary,
                    onTap: () => _push(context, const PictureSettingsScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.equalizer,
                    title: 'Sound',
                    subtitle: 'Audio EQ & output',
                    color: AppColors.secondary,
                    onTap: () => _push(context, const SoundSettingsScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.share,
                    title: 'Share',
                    subtitle: 'Export & import setup',
                    color: AppColors.primary,
                    onTap: () => _push(context, const QrShareScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.sports_esports,
                    title: 'Game Pad',
                    subtitle: 'Gaming controller layout',
                    color: AppColors.signalEmerald,
                    onTap: () => _push(context, const GamePadScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.nightlight_round,
                    title: 'Ambient',
                    subtitle: 'Dock mode clock & remote',
                    color: AppColors.tertiary,
                    onTap: () => _push(context, const AmbientDisplayScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.subtitles,
                    title: 'Subtitles',
                    subtitle: 'Caption size & language',
                    color: AppColors.secondary,
                    onTap: () => _push(context, const SubtitleManagerScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.dashboard_customize,
                    title: 'Quick Dash',
                    subtitle: 'Customisable action grid',
                    color: AppColors.primary,
                    onTap: () => _push(context, const QuickDashboardScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.motion_photos_on,
                    title: 'Motion',
                    subtitle: 'Tilt & shake control',
                    color: AppColors.signalEmerald,
                    onTap: () => _push(context, const MotionControlScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.live_tv,
                    title: 'Guide',
                    subtitle: 'Channel browser & EPG',
                    color: AppColors.error,
                    onTap: () => _push(context, const ChannelGuideScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.child_care,
                    title: 'Timer',
                    subtitle: 'Viewing time limits',
                    color: AppColors.alertAmber,
                    onTap: () => _push(context, const ParentalTimerScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.accessibility_new,
                    title: 'Access',
                    subtitle: 'Large buttons & contrast',
                    color: AppColors.tertiary,
                    onTap: () => _push(context, const AccessibilityScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.palette,
                    title: 'Themes',
                    subtitle: 'App colour & accent',
                    color: AppColors.secondary,
                    onTap: () => _push(context, const RemoteThemesScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.volume_up,
                    title: 'Volume',
                    subtitle: 'Presets & limiter',
                    color: AppColors.primary,
                    onTap: () => _push(context, const VolumeLimiterScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.power,
                    title: 'WoL',
                    subtitle: 'Wake TV over network',
                    color: AppColors.signalEmerald,
                    onTap: () => _push(context, const WakeOnLanScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.dialpad,
                    title: 'Dial',
                    subtitle: 'Channel number entry',
                    color: AppColors.error,
                    onTap: () => _push(context, const QuickDialScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.display_settings,
                    title: 'Media',
                    subtitle: 'Signal & format info',
                    color: AppColors.tertiary,
                    onTap: () => _push(context, const MediaInfoScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.screen_lock_portrait,
                    title: 'Timeout',
                    subtitle: 'Saver & auto power',
                    color: AppColors.secondary,
                    onTap: () => _push(context, const ScreenTimeoutScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.bolt,
                    title: 'Energy',
                    subtitle: 'Power cost estimate',
                    color: AppColors.alertAmber,
                    onTap: () => _push(context, const EnergyMonitorScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.settings_remote,
                    title: 'IR Learn',
                    subtitle: 'Copy remote codes',
                    color: AppColors.primary,
                    onTap: () => _push(context, const IrLearningScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.bedtime,
                    title: 'Sleep',
                    subtitle: 'Ambient sounds & timer',
                    color: AppColors.secondary,
                    onTap: () => _push(context, const SleepSoundsScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.connected_tv,
                    title: 'My TVs',
                    subtitle: 'Multi-TV switcher',
                    color: AppColors.primary,
                    onTap: () => _push(context, const MultiTvScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.label,
                    title: 'Inputs',
                    subtitle: 'Rename HDMI ports',
                    color: AppColors.tertiary,
                    onTap: () => _push(context, const InputRenameScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.bug_report,
                    title: 'Logs',
                    subtitle: 'Diagnostic viewer',
                    color: AppColors.alertAmber,
                    onTap: () => _push(context, const DiagnosticLogScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.palette,
                    title: 'Colour',
                    subtitle: 'TV test patterns',
                    color: AppColors.error,
                    onTap: () => _push(context, const ColourTestScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.child_care,
                    title: 'Kids',
                    subtitle: 'Child-safe remote',
                    color: AppColors.signalEmerald,
                    onTap: () => _push(context, const ChildProfileScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.wifi_find,
                    title: 'Network',
                    subtitle: 'Connection info',
                    color: AppColors.primary,
                    onTap: () => _push(context, const NetworkInfoScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.apps,
                    title: 'TV Apps',
                    subtitle: 'App organiser',
                    color: AppColors.tertiary,
                    onTap: () => _push(context, const TvAppManagerScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.content_paste,
                    title: 'Clipboard',
                    subtitle: 'Phone-to-TV text',
                    color: AppColors.secondary,
                    onTap: () => _push(context, const RemoteClipboardScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.notifications_active,
                    title: 'Find TV',
                    subtitle: 'Make TV beep',
                    color: AppColors.alertAmber,
                    onTap: () => _push(context, const WhistleFinderScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.system_update,
                    title: 'Firmware',
                    subtitle: 'TV system info',
                    color: AppColors.primary,
                    onTap: () => _push(context, const FirmwareInfoScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.notifications,
                    title: 'Alerts',
                    subtitle: 'Manage alerts',
                    color: AppColors.alertAmber,
                    onTap: () =>
                        _push(context, const NotificationManagerScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.speed,
                    title: 'Speed Test',
                    subtitle: 'Network speed',
                    color: AppColors.signalEmerald,
                    onTap: () => _push(context, const SpeedTestScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.schedule,
                    title: 'Power Timer',
                    subtitle: 'Auto on/off',
                    color: AppColors.tertiary,
                    onTap: () => _push(context, const PowerScheduleScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.aspect_ratio,
                    title: 'Aspect Ratio',
                    subtitle: 'Screen format',
                    color: AppColors.secondary,
                    onTap: () => _push(context, const AspectRatioScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.mouse,
                    title: 'Mouse',
                    subtitle: 'Cursor pointer mode',
                    color: AppColors.primary,
                    onTap: () => _push(context, const MouseCursorScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.picture_in_picture_alt,
                    title: 'Floating',
                    subtitle: 'Overlay mini remote',
                    color: AppColors.tertiary,
                    onTap: () => _push(context, const FloatingRemoteScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.screenshot_monitor,
                    title: 'TV Shot',
                    subtitle: 'Capture TV screen',
                    color: AppColors.signalEmerald,
                    onTap: () => _push(context, const TvScreenshotScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.queue_music,
                    title: 'Cast Queue',
                    subtitle: 'Media playlist cast',
                    color: AppColors.secondary,
                    onTap: () => _push(context, const CastQueueScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.monitor_heart,
                    title: 'Pulse',
                    subtitle: 'Live signal health',
                    color: AppColors.error,
                    onTap: () => _push(context, const ConnectionPulseScreen()),
                  ),
                  // ── batch 12 ──
                  _ToolCard(
                    icon: Icons.link,
                    title: 'Deep Link',
                    subtitle: 'Send URLs to TV',
                    color: AppColors.primary,
                    onTap: () => _push(context, const DeepLinkScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.visibility,
                    title: 'Wakelock',
                    subtitle: 'Keep screen on',
                    color: AppColors.alertAmber,
                    onTap: () => _push(context, const WakelockScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.speaker_group,
                    title: 'Audio Out',
                    subtitle: 'TV audio routing',
                    color: AppColors.tertiary,
                    onTap: () => _push(context, const AudioOutputScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.qr_code_scanner,
                    title: 'QR Connect',
                    subtitle: 'Scan to pair TV',
                    color: AppColors.signalEmerald,
                    onTap: () => _push(context, const QrConnectScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.text_snippet,
                    title: 'Templates',
                    subtitle: 'Quick text snippets',
                    color: AppColors.secondary,
                    onTap: () => _push(context, const TextTemplatesScreen()),
                  ),
                  // ── batch 13 ──
                  _ToolCard(
                    icon: Icons.vibration,
                    title: 'Haptics',
                    subtitle: 'Vibration feedback',
                    color: AppColors.primary,
                    onTap: () => _push(context, const HapticFeedbackScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.info_outline,
                    title: 'Device Info',
                    subtitle: 'TV hardware details',
                    color: AppColors.tertiary,
                    onTap: () => _push(context, const DeviceInfoScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.swap_vert,
                    title: 'Auto Scroll',
                    subtitle: 'Timed page scroll',
                    color: AppColors.signalEmerald,
                    onTap: () => _push(context, const AutoScrollScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.wallpaper,
                    title: 'Screen Saver',
                    subtitle: 'Ambient display',
                    color: AppColors.alertAmber,
                    onTap: () => _push(context, const ScreenSaverScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.tune,
                    title: 'Quick Panel',
                    subtitle: 'TV control center',
                    color: AppColors.secondary,
                    onTap: () => _push(context, const QuickSettingsScreen()),
                  ),
                  // ── batch 14 ──
                  _ToolCard(
                    icon: Icons.notifications_active,
                    title: 'TV Alerts',
                    subtitle: 'Notification hub',
                    color: AppColors.error,
                    onTap: () => _push(context, const TvNotificationsScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.keyboard,
                    title: 'Layouts',
                    subtitle: 'Keyboard languages',
                    color: AppColors.primary,
                    onTap: () => _push(context, const KeyboardLayoutsScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.record_voice_over,
                    title: 'Voice Cmds',
                    subtitle: 'Speak to control',
                    color: AppColors.tertiary,
                    onTap: () => _push(context, const VoiceCommandsScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.devices,
                    title: 'Multi-Device',
                    subtitle: 'Control many TVs',
                    color: AppColors.signalEmerald,
                    onTap: () => _push(context, const MultiDeviceScreen()),
                  ),
                  // ── batch 15 ──
                  _ToolCard(
                    icon: Icons.photo_library,
                    title: 'Photo Cast',
                    subtitle: 'Cast photos to TV',
                    color: AppColors.primary,
                    onTap: () => _push(context, const PhotoCastScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.alarm,
                    title: 'TV Alarm',
                    subtitle: 'Wake up with TV',
                    color: AppColors.alertAmber,
                    onTap: () => _push(context, const TvAlarmScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.sticky_note_2,
                    title: 'Notes',
                    subtitle: 'Jot while watching',
                    color: AppColors.tertiary,
                    onTap: () => _push(context, const QuickNotesScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.group,
                    title: 'Share',
                    subtitle: 'Multi-phone remote',
                    color: AppColors.secondary,
                    onTap: () => _push(context, const RemoteSharingScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.swipe,
                    title: 'Swipe',
                    subtitle: 'Full-screen gestures',
                    color: AppColors.signalEmerald,
                    onTap: () => _push(context, const SwipeRemoteScreen()),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _header() => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: hex(AppColors.surface),
          border: Border(
              bottom: BorderSide(
                  color: hex(AppColors.outlineVariant).withValues(alpha: 0.6))),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 448),
            child: Row(
              children: [
                Icon(Icons.build_rounded,
                    size: 20, color: hex(AppColors.primaryContainer)),
                const SizedBox(width: AppSpacing.sm),
                Text('Tools',
                    style: gfont(AppType.headlineMd,
                        color: hex(AppColors.onSurface),
                        size: 16,
                        weight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      );

  void _push(BuildContext context, Widget screen) {
    final c = RemoteScope.of(context);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => RemoteScope(controller: c, child: screen),
    ));
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final int color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: panel(),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: hex(color).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Icon(icon, color: hex(color), size: 22),
            ),
            const Spacer(),
            Text(title,
                style: gfont(AppType.bodyMd,
                    color: hex(AppColors.onSurface),
                    weight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: gfont(AppType.bodySm,
                    color: hex(AppColors.onSurfaceVariant))),
          ],
        ),
      ),
    );
  }
}
