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
import 'tv_calendar_screen.dart';
import 'countdown_timer_screen.dart';
import 'ip_camera_screen.dart';
import 'weather_display_screen.dart';
import 'content_bookmarks_screen.dart';
import 'tv_trivia_screen.dart';
import 'sound_eq_screen.dart';
import 'remote_log_screen.dart';
import 'shortcut_widgets_screen.dart';
import 'cast_timer_screen.dart';
import 'multi_audio_screen.dart';
import 'screen_zoom_screen.dart';
import 'tv_storage_screen.dart';
import 'channel_recorder_screen.dart';
import 'family_voting_screen.dart';
import 'hdmi_switcher_screen.dart';
import 'tv_cleaner_screen.dart';
import 'sound_test_screen.dart';
import 'watch_party_screen.dart';
import 'tv_shortcuts_screen.dart';
import 'screen_rotate_screen.dart';
import 'tv_dictionary_screen.dart';
import 'ambient_sounds_screen.dart';
import 'channel_lock_screen.dart';
import 'quick_poll_screen.dart';
import 'tv_roulette_screen.dart';
import 'routine_builder_screen.dart';
import 'signal_meter_screen.dart';
import 'caption_style_screen.dart';
import 'find_remote_screen.dart';
import 'movie_trivia_screen.dart';
import 'volume_scheduler_screen.dart';
import 'input_labeler_screen.dart';
import 'mirror_qr_screen.dart';
import 'remote_trainer_screen.dart';
import 'gesture_recorder_screen.dart';
import 'tv_workout_screen.dart';
import 'audio_delay_screen.dart';
import 'remote_battery_screen.dart';
import 'channel_sort_screen.dart';
import 'pip_mode_screen.dart';
import 'remote_sounds_screen.dart';
import 'tv_brightness_screen.dart';
import 'watch_history_screen.dart';
import 'parental_report_screen.dart';
import 'tv_magnifier_screen.dart';
import 'sound_profile_screen.dart';
import 'channel_map_screen.dart';
import 'screen_dimmer_screen.dart';
import 'gesture_library_screen.dart';
import 'remote_vibrate_screen.dart';
import 'channel_blocker_screen.dart';
import 'tv_wallpaper_screen.dart';
import 'quick_switch_screen.dart';
import 'screen_annotate_screen.dart';
import 'screen_cast_screen.dart';
import 'button_remap_screen.dart';
import 'tv_color_screen.dart';
import 'app_timer_screen.dart';
import 'voice_dictation_screen.dart';
import 'tv_resolution_screen.dart';
import 'scene_mode_screen.dart';
import 'auto_volume_screen.dart';
import 'remote_gesture_pad_screen.dart';
import 'voice_macro_screen.dart';
import 'network_block_screen.dart';
import 'cast_history_screen.dart';
import 'led_control_screen.dart';
import 'vibrate_profile_screen.dart';
import 'smart_home_hub_screen.dart';
import 'media_server_screen.dart';
import 'bandwidth_monitor_screen.dart';
import 'sleep_routine_screen.dart';
import 'channel_preview_screen.dart';
import 'tv_bingo_screen.dart';
import 'eco_mode_screen.dart';
import 'couch_buzz_screen.dart';
import 'stream_radar_screen.dart';
import 'watch_later_screen.dart';
import 'focus_timer_screen.dart';
import 'noise_gate_screen.dart';
import 'sleep_fade_screen.dart';
import 'parental_pin_screen.dart';
import 'tv_karaoke_screen.dart';
import 'remote_compass_screen.dart';
import 'app_usage_chart_screen.dart';
import 'quick_translate_screen.dart';
import 'tv_health_check_screen.dart';
import 'remote_scheduler_screen.dart';
import 'sound_zones_screen.dart';
import 'screen_split_screen.dart';
import 'content_filter_screen.dart';
import 'remote_macro_pad_screen.dart';
import 'tv_weather_screen.dart';
import 'sound_eq_pro_screen.dart';
import 'channel_fav_grid_screen.dart';
import 'screen_record_screen.dart';
// ── batch 36 imports ──
import 'sports_score_screen.dart';
import 'room_light_screen.dart';
import 'power_stats_screen.dart';
import 'channel_filter_screen.dart';
import 'macro_runner_screen.dart';

class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_ToolCard> _allCards(BuildContext context) => [
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
                  // ── batch 16 ──
                  _ToolCard(
                    icon: Icons.calendar_month,
                    title: 'Calendar',
                    subtitle: 'TV viewing reminders',
                    color: AppColors.primary,
                    onTap: () => _push(context, const TvCalendarScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.timer,
                    title: 'Timer',
                    subtitle: 'Countdown & stopwatch',
                    color: AppColors.alertAmber,
                    onTap: () => _push(context, const CountdownTimerScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.videocam,
                    title: 'Cameras',
                    subtitle: 'IP camera viewer',
                    color: AppColors.secondary,
                    onTap: () => _push(context, const IpCameraScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.cloud,
                    title: 'Weather',
                    subtitle: 'Weather dashboard',
                    color: AppColors.tertiary,
                    onTap: () => _push(context, const WeatherDisplayScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.bookmark,
                    title: 'Bookmarks',
                    subtitle: 'Content watch list',
                    color: AppColors.signalEmerald,
                    onTap: () => _push(context, const ContentBookmarksScreen()),
                  ),
                  // ── batch 17 ──
                  _ToolCard(
                    icon: Icons.quiz,
                    title: 'Trivia',
                    subtitle: 'TV quiz game',
                    color: AppColors.alertAmber,
                    onTap: () => _push(context, const TvTriviaScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.equalizer,
                    title: 'Sound EQ',
                    subtitle: 'Audio equalizer',
                    color: AppColors.secondary,
                    onTap: () => _push(context, const SoundEqScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.history,
                    title: 'Remote Log',
                    subtitle: 'Command history',
                    color: AppColors.primary,
                    onTap: () => _push(context, const RemoteLogScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.widgets,
                    title: 'Widgets',
                    subtitle: 'Quick action config',
                    color: AppColors.tertiary,
                    onTap: () => _push(context, const ShortcutWidgetsScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.timer,
                    title: 'Cast Timer',
                    subtitle: 'Auto-stop casting',
                    color: AppColors.error,
                    onTap: () => _push(context, const CastTimerScreen()),
                  ),
                  // ── batch 18 ──
                  _ToolCard(
                    icon: Icons.surround_sound,
                    title: 'Multi Audio',
                    subtitle: 'Audio tracks',
                    color: AppColors.secondary,
                    onTap: () => _push(context, const MultiAudioScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.zoom_in,
                    title: 'Screen Zoom',
                    subtitle: 'Zoom & pan TV',
                    color: AppColors.primary,
                    onTap: () => _push(context, const ScreenZoomScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.storage,
                    title: 'TV Storage',
                    subtitle: 'Manage storage',
                    color: AppColors.alertAmber,
                    onTap: () => _push(context, const TvStorageScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.fiber_manual_record,
                    title: 'Recorder',
                    subtitle: 'Schedule recordings',
                    color: AppColors.error,
                    onTap: () => _push(context, const ChannelRecorderScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.how_to_vote,
                    title: 'Family Vote',
                    subtitle: 'Vote what to watch',
                    color: AppColors.signalEmerald,
                    onTap: () => _push(context, const FamilyVotingScreen()),
                  ),
                  // ── batch 19 ──
                  _ToolCard(
                    icon: Icons.settings_input_hdmi,
                    title: 'HDMI Switch',
                    subtitle: 'Switch inputs',
                    color: AppColors.primary,
                    onTap: () => _push(context, const HdmiSwitcherScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.cleaning_services,
                    title: 'TV Cleaner',
                    subtitle: 'Screen clean mode',
                    color: AppColors.signalEmerald,
                    onTap: () => _push(context, const TvCleanerScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.speaker_group,
                    title: 'Sound Test',
                    subtitle: 'Test speakers',
                    color: AppColors.secondary,
                    onTap: () => _push(context, const SoundTestScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.groups,
                    title: 'Watch Party',
                    subtitle: 'Sync viewing',
                    color: AppColors.tertiary,
                    onTap: () => _push(context, const WatchPartyScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.rocket_launch,
                    title: 'TV Shortcuts',
                    subtitle: 'Quick launch apps',
                    color: AppColors.alertAmber,
                    onTap: () => _push(context, const TvShortcutsScreen()),
                  ),
                  // ── batch 20 ──
                  _ToolCard(
                    icon: Icons.screen_rotation,
                    title: 'Screen Rotate',
                    subtitle: 'Rotate display',
                    color: AppColors.secondary,
                    onTap: () => _push(context, const ScreenRotateScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.menu_book,
                    title: 'TV Dictionary',
                    subtitle: 'Look up words',
                    color: AppColors.primary,
                    onTap: () => _push(context, const TvDictionaryScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.spa,
                    title: 'Ambient Sound',
                    subtitle: 'Relaxing audio',
                    color: AppColors.signalEmerald,
                    onTap: () => _push(context, const AmbientSoundsScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.lock,
                    title: 'Channel Lock',
                    subtitle: 'PIN-lock channels',
                    color: AppColors.error,
                    onTap: () => _push(context, const ChannelLockScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.poll,
                    title: 'Quick Poll',
                    subtitle: 'Household polls',
                    color: AppColors.alertAmber,
                    onTap: () => _push(context, const QuickPollScreen()),
                  ),
                  // ── batch 21 ──
                  _ToolCard(
                    icon: Icons.casino,
                    title: 'TV Roulette',
                    subtitle: 'Random pick',
                    color: AppColors.alertAmber,
                    onTap: () => _push(context, const TvRouletteScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.auto_fix_high,
                    title: 'Routines',
                    subtitle: 'Multi-step actions',
                    color: AppColors.secondary,
                    onTap: () => _push(context, const RoutineBuilderScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.signal_cellular_alt,
                    title: 'Signal Meter',
                    subtitle: 'Connection quality',
                    color: AppColors.signalEmerald,
                    onTap: () => _push(context, const SignalMeterScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.closed_caption,
                    title: 'Caption Style',
                    subtitle: 'Subtitle look',
                    color: AppColors.primary,
                    onTap: () => _push(context, const CaptionStyleScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.notifications_active,
                    title: 'Find Remote',
                    subtitle: 'Ring TV speaker',
                    color: AppColors.error,
                    onTap: () => _push(context, const FindRemoteScreen()),
                  ),
                  // ── batch 22 ──
                  _ToolCard(
                    icon: Icons.quiz,
                    title: 'Movie Trivia',
                    subtitle: 'TV quiz game',
                    color: AppColors.tertiary,
                    onTap: () => _push(context, const MovieTriviaScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.schedule,
                    title: 'Volume Schedule',
                    subtitle: 'Time-based vol',
                    color: AppColors.primary,
                    onTap: () => _push(context, const VolumeSchedulerScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.label,
                    title: 'Input Labeler',
                    subtitle: 'Name HDMI ports',
                    color: AppColors.alertAmber,
                    onTap: () => _push(context, const InputLabelerScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.qr_code_2,
                    title: 'Mirror QR',
                    subtitle: 'Screen mirroring',
                    color: AppColors.secondary,
                    onTap: () => _push(context, const MirrorQrScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.school,
                    title: 'Remote Trainer',
                    subtitle: 'Learn controls',
                    color: AppColors.signalEmerald,
                    onTap: () => _push(context, const RemoteTrainerScreen()),
                  ),
                  // ── batch 23 ──
                  _ToolCard(
                    icon: Icons.fiber_manual_record,
                    title: 'Gesture Recorder',
                    subtitle: 'Record macros',
                    color: AppColors.tertiary,
                    onTap: () => _push(context, const GestureRecorderScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.fitness_center,
                    title: 'TV Workout',
                    subtitle: 'Exercise guide',
                    color: AppColors.signalEmerald,
                    onTap: () => _push(context, const TvWorkoutScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.graphic_eq,
                    title: 'Audio Delay',
                    subtitle: 'Fix lip sync',
                    color: AppColors.primary,
                    onTap: () => _push(context, const AudioDelayScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.battery_5_bar,
                    title: 'Remote Battery',
                    subtitle: 'Battery monitor',
                    color: AppColors.alertAmber,
                    onTap: () => _push(context, const RemoteBatteryScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.sort,
                    title: 'Channel Sort',
                    subtitle: 'Reorder favorites',
                    color: AppColors.secondary,
                    onTap: () => _push(context, const ChannelSortScreen()),
                  ),
                  // ── batch 24 ──
                  _ToolCard(
                    icon: Icons.picture_in_picture_alt,
                    title: 'PIP Mode',
                    subtitle: 'Picture-in-picture',
                    color: AppColors.primary,
                    onTap: () => _push(context, const PipModeScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.music_note,
                    title: 'Remote Sounds',
                    subtitle: 'Button sound FX',
                    color: AppColors.secondary,
                    onTap: () => _push(context, const RemoteSoundsScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.brightness_6,
                    title: 'TV Brightness',
                    subtitle: 'Display controls',
                    color: AppColors.alertAmber,
                    onTap: () => _push(context, const TvBrightnessScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.history,
                    title: 'Watch History',
                    subtitle: 'Viewing log',
                    color: AppColors.tertiary,
                    onTap: () => _push(context, const WatchHistoryScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.family_restroom,
                    title: 'Parental Report',
                    subtitle: 'Weekly stats',
                    color: AppColors.signalEmerald,
                    onTap: () => _push(context, const ParentalReportScreen()),
                  ),
                  // ── batch 25 ──
                  _ToolCard(
                    icon: Icons.zoom_in,
                    title: 'TV Magnifier',
                    subtitle: 'Screen zoom',
                    color: AppColors.primary,
                    onTap: () => _push(context, const TvMagnifierScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.equalizer,
                    title: 'Sound Profile',
                    subtitle: 'Audio presets',
                    color: AppColors.secondary,
                    onTap: () => _push(context, const SoundProfileScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.map,
                    title: 'Channel Map',
                    subtitle: 'Visual guide',
                    color: AppColors.tertiary,
                    onTap: () => _push(context, const ChannelMapScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.brightness_3,
                    title: 'Screen Dimmer',
                    subtitle: 'Night brightness',
                    color: AppColors.alertAmber,
                    onTap: () => _push(context, const ScreenDimmerScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.gesture,
                    title: 'Gesture Library',
                    subtitle: 'Learn gestures',
                    color: AppColors.signalEmerald,
                    onTap: () => _push(context, const GestureLibraryScreen()),
                  ),
                  // ── batch 26 ──
                  _ToolCard(
                    icon: Icons.vibration,
                    title: 'Remote Vibrate',
                    subtitle: 'Haptic patterns',
                    color: AppColors.secondary,
                    onTap: () => _push(context, const RemoteVibrateScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.block,
                    title: 'Channel Blocker',
                    subtitle: 'Hide channels',
                    color: AppColors.error,
                    onTap: () => _push(context, const ChannelBlockerScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.wallpaper,
                    title: 'TV Wallpaper',
                    subtitle: 'Ambient art',
                    color: AppColors.primary,
                    onTap: () => _push(context, const TvWallpaperScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.swap_horiz,
                    title: 'Quick Switch',
                    subtitle: 'App & input swap',
                    color: AppColors.signalEmerald,
                    onTap: () => _push(context, const QuickSwitchScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.edit,
                    title: 'Screen Annotate',
                    subtitle: 'Draw on screen',
                    color: AppColors.alertAmber,
                    onTap: () => _push(context, const ScreenAnnotateScreen()),
                  ),
                  // ── batch 27 ──
                  _ToolCard(
                    icon: Icons.cast,
                    title: 'Screen Cast',
                    subtitle: 'Mirror to TV',
                    color: AppColors.primary,
                    onTap: () => _push(context, const ScreenCastScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.shuffle,
                    title: 'Button Remap',
                    subtitle: 'Reassign buttons',
                    color: AppColors.secondary,
                    onTap: () => _push(context, const ButtonRemapScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.palette,
                    title: 'TV Color',
                    subtitle: 'Color controls',
                    color: AppColors.tertiary,
                    onTap: () => _push(context, const TvColorScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.timer,
                    title: 'App Timer',
                    subtitle: 'Usage limits',
                    color: AppColors.alertAmber,
                    onTap: () => _push(context, const AppTimerScreen()),
                  ),
                  // ── batch 28 ──
                  _ToolCard(
                    icon: Icons.record_voice_over,
                    title: 'Voice Dictation',
                    subtitle: 'Speak to TV',
                    color: AppColors.primary,
                    onTap: () => _push(context, const VoiceDictationScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.tv,
                    title: 'TV Resolution',
                    subtitle: 'Display settings',
                    color: AppColors.signalEmerald,
                    onTap: () => _push(context, const TvResolutionScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.movie,
                    title: 'Scene Mode',
                    subtitle: 'Picture presets',
                    color: AppColors.tertiary,
                    onTap: () => _push(context, const SceneModeScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.graphic_eq,
                    title: 'Auto Volume',
                    subtitle: 'Level audio',
                    color: AppColors.secondary,
                    onTap: () => _push(context, const AutoVolumeScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.swipe,
                    title: 'Gesture Pad',
                    subtitle: 'Swipe control',
                    color: AppColors.alertAmber,
                    onTap: () => _push(context, const RemoteGesturePadScreen()),
                  ),
                  // ── batch 29 ──
                  _ToolCard(
                    icon: Icons.mic,
                    title: 'Voice Macro',
                    subtitle: 'Speak to trigger',
                    color: AppColors.primary,
                    onTap: () => _push(context, const VoiceMacroScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.shield,
                    title: 'Network Block',
                    subtitle: 'App firewall',
                    color: AppColors.error,
                    onTap: () => _push(context, const NetworkBlockScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.cast_connected,
                    title: 'Cast History',
                    subtitle: 'Session log',
                    color: AppColors.secondary,
                    onTap: () => _push(context, const CastHistoryScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.light_mode,
                    title: 'LED Control',
                    subtitle: 'Ambient lighting',
                    color: AppColors.tertiary,
                    onTap: () => _push(context, const LedControlScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.vibration,
                    title: 'Vibrate Profiles',
                    subtitle: 'Haptic events',
                    color: AppColors.alertAmber,
                    onTap: () => _push(context, const VibrateProfileScreen()),
                  ),
                  // ── batch 30 ──
                  _ToolCard(
                    icon: Icons.home,
                    title: 'Smart Home Hub',
                    subtitle: 'Device control',
                    color: AppColors.primary,
                    onTap: () => _push(context, const SmartHomeHubScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.dns,
                    title: 'Media Server',
                    subtitle: 'DLNA streaming',
                    color: AppColors.signalEmerald,
                    onTap: () => _push(context, const MediaServerScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.speed,
                    title: 'Bandwidth',
                    subtitle: 'Network monitor',
                    color: AppColors.secondary,
                    onTap: () => _push(context, const BandwidthMonitorScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.bedtime,
                    title: 'Sleep Routine',
                    subtitle: 'Wind-down timer',
                    color: AppColors.tertiary,
                    onTap: () => _push(context, const SleepRoutineScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.preview,
                    title: 'Channel Preview',
                    subtitle: 'Browse channels',
                    color: AppColors.alertAmber,
                    onTap: () => _push(context, const ChannelPreviewScreen()),
                  ),
                  // ── batch 31 ──
                  _ToolCard(
                    icon: Icons.grid_on,
                    title: 'TV Bingo',
                    subtitle: 'Watch party game',
                    color: AppColors.primary,
                    onTap: () => _push(context, const TvBingoScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.eco,
                    title: 'Eco Mode',
                    subtitle: 'Energy saver',
                    color: AppColors.signalEmerald,
                    onTap: () => _push(context, const EcoModeScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.vibration,
                    title: 'Couch Buzz',
                    subtitle: 'Phone alerts',
                    color: AppColors.secondary,
                    onTap: () => _push(context, const CouchBuzzScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.radar,
                    title: 'Stream Radar',
                    subtitle: 'New content',
                    color: AppColors.tertiary,
                    onTap: () => _push(context, const StreamRadarScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.bookmark,
                    title: 'Watch Later',
                    subtitle: 'Queue manager',
                    color: AppColors.alertAmber,
                    onTap: () => _push(context, const WatchLaterScreen()),
                  ),
                  // ── batch 32 ──
                  _ToolCard(
                    icon: Icons.self_improvement,
                    title: 'Focus Timer',
                    subtitle: 'Pomodoro focus',
                    color: AppColors.primary,
                    onTap: () => _push(context, const FocusTimerScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.noise_aware,
                    title: 'Noise Gate',
                    subtitle: 'Auto-mute loud',
                    color: AppColors.secondary,
                    onTap: () => _push(context, const NoiseGateScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.bedtime,
                    title: 'Sleep Fade',
                    subtitle: 'Volume fade-out',
                    color: AppColors.tertiary,
                    onTap: () => _push(context, const SleepFadeScreen()),
                  ),
                  // ── batch 33 ──
                  _ToolCard(
                    icon: Icons.pin,
                    title: 'Parental PIN',
                    subtitle: 'PIN lock',
                    color: AppColors.error,
                    onTap: () => _push(context, const ParentalPinScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.mic,
                    title: 'TV Karaoke',
                    subtitle: 'Sing along',
                    color: AppColors.secondary,
                    onTap: () => _push(context, const TvKaraokeScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.explore,
                    title: 'Remote Compass',
                    subtitle: 'D-pad orient',
                    color: AppColors.primary,
                    onTap: () => _push(context, const RemoteCompassScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.bar_chart,
                    title: 'App Usage',
                    subtitle: 'Usage chart',
                    color: AppColors.tertiary,
                    onTap: () => _push(context, const AppUsageChartScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.translate,
                    title: 'Quick Translate',
                    subtitle: 'Translate & send',
                    color: AppColors.signalEmerald,
                    onTap: () => _push(context, const QuickTranslateScreen()),
                  ),
                  // ── batch 34 ──
                  _ToolCard(
                    icon: Icons.health_and_safety,
                    title: 'TV Health Check',
                    subtitle: 'Diagnostics',
                    color: AppColors.signalEmerald,
                    onTap: () => _push(context, const TvHealthCheckScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.schedule,
                    title: 'Remote Scheduler',
                    subtitle: 'Timed actions',
                    color: AppColors.primary,
                    onTap: () => _push(context, const RemoteSchedulerScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.surround_sound,
                    title: 'Sound Zones',
                    subtitle: 'Multi-room audio',
                    color: AppColors.secondary,
                    onTap: () => _push(context, const SoundZonesScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.splitscreen,
                    title: 'Screen Split',
                    subtitle: 'Multi-view',
                    color: AppColors.tertiary,
                    onTap: () => _push(context, const ScreenSplitScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.shield,
                    title: 'Content Filter',
                    subtitle: 'Rating filter',
                    color: AppColors.error,
                    onTap: () => _push(context, const ContentFilterScreen()),
                  ),
                  // ── batch 35 ──
                  _ToolCard(
                    icon: Icons.grid_view,
                    title: 'Macro Pad',
                    subtitle: 'Key sequences',
                    color: AppColors.primary,
                    onTap: () => _push(context, const RemoteMacroPadScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.wb_sunny,
                    title: 'TV Weather',
                    subtitle: 'Forecast cast',
                    color: AppColors.alertAmber,
                    onTap: () => _push(context, const TvWeatherScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.equalizer,
                    title: 'Sound EQ Pro',
                    subtitle: '5-band EQ',
                    color: AppColors.secondary,
                    onTap: () => _push(context, const SoundEqProScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.star,
                    title: 'Fav Channels',
                    subtitle: 'Channel grid',
                    color: AppColors.alertAmber,
                    onTap: () => _push(context, const ChannelFavGridScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.videocam,
                    title: 'Screen Record',
                    subtitle: 'TV capture',
                    color: AppColors.error,
                    onTap: () => _push(context, const ScreenRecordScreen()),
                  ),
                  // ── batch 36 ──
                  _ToolCard(
                    icon: Icons.sports,
                    title: 'Sports Score',
                    subtitle: 'Live scores',
                    color: AppColors.error,
                    onTap: () => _push(context, const SportsScoreScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.light_mode,
                    title: 'Room Light',
                    subtitle: 'Ambient sync',
                    color: AppColors.alertAmber,
                    onTap: () => _push(context, const RoomLightScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.bolt,
                    title: 'Power Stats',
                    subtitle: 'Usage analytics',
                    color: AppColors.signalEmerald,
                    onTap: () => _push(context, const PowerStatsScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.block,
                    title: 'Channel Filter',
                    subtitle: 'Block channels',
                    color: AppColors.error,
                    onTap: () => _push(context, const ChannelFilterScreen()),
                  ),
                  _ToolCard(
                    icon: Icons.play_circle_outline,
                    title: 'Macro Runner',
                    subtitle: 'Run macros',
                    color: AppColors.tertiary,
                    onTap: () => _push(context, const MacroRunnerScreen()),
                  ),
  ];

  @override
  Widget build(BuildContext context) {
    final cards = _allCards(context);
    final filtered = _query.isEmpty
        ? cards
        : cards
            .where((c) =>
                c.title.toLowerCase().contains(_query) ||
                c.subtitle.toLowerCase().contains(_query))
            .toList();

    return Column(
      children: [
        _header(),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 448),
              child: filtered.isEmpty
                  ? _emptySearch()
                  : GridView.count(
                      crossAxisCount: 2,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      mainAxisSpacing: AppSpacing.md,
                      crossAxisSpacing: AppSpacing.md,
                      childAspectRatio: 1.1,
                      children: filtered,
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _emptySearch() => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 48,
              color: hex(AppColors.outline).withValues(alpha: 0.3)),
          const SizedBox(height: 8),
          Text('No tools found',
              style: gfont(AppType.bodyMd,
                  color: hex(AppColors.onSurface),
                  weight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Try a different search term',
              style: gfont(AppType.bodySm,
                  color: hex(AppColors.outline), size: 11)),
        ],
      );

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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.build_rounded,
                        size: 20, color: hex(AppColors.primaryContainer)),
                    const SizedBox(width: AppSpacing.sm),
                    Text('Tools',
                        style: gfont(AppType.headlineMd,
                            color: hex(AppColors.onSurface),
                            size: 16,
                            weight: FontWeight.w600)),
                    const Spacer(),
                    Text(
                      '${_allCards(context).length}',
                      style: gfont(AppType.bodySm,
                          color: hex(AppColors.outline), size: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) =>
                        setState(() => _query = v.trim().toLowerCase()),
                    style: gfont(AppType.bodyMd,
                        color: hex(AppColors.onSurface), size: 13),
                    decoration: InputDecoration(
                      hintText: 'Search tools...',
                      hintStyle: gfont(AppType.bodySm,
                          color: hex(AppColors.outline).withValues(alpha: 0.5),
                          size: 12),
                      prefixIcon: Icon(Icons.search,
                          size: 18,
                          color: hex(AppColors.outline).withValues(alpha: 0.5)),
                      suffixIcon: _query.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _searchCtrl.clear();
                                setState(() => _query = '');
                              },
                              child: Icon(Icons.close,
                                  size: 16, color: hex(AppColors.outline)),
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 0),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        borderSide: BorderSide(
                            color: hex(AppColors.outlineVariant)
                                .withValues(alpha: 0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        borderSide: BorderSide(
                            color: hex(AppColors.outlineVariant)
                                .withValues(alpha: 0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        borderSide: BorderSide(
                            color: hex(AppColors.primary).withValues(alpha: 0.5)),
                      ),
                      filled: true,
                      fillColor: hex(AppColors.surfaceContainerLow),
                    ),
                  ),
                ),
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
