## Añade los <queries> al manifiesto al exportar a Android (requiere build con Gradle).
## Sin ellos, Android 11+ oculta las demás apps a queryIntentActivities() y getLaunchIntentForPackage().
@tool
extends EditorPlugin

var _export_plugin: EditorExportPlugin


func _enter_tree() -> void:
	_export_plugin = AppVisibilityExport.new()
	add_export_plugin(_export_plugin)


func _exit_tree() -> void:
	remove_export_plugin(_export_plugin)
	_export_plugin = null


class AppVisibilityExport extends EditorExportPlugin:
	func _get_name() -> String:
		return "NebulaVRAppVisibility"

	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAndroid

	func _get_android_manifest_element_contents(_platform: EditorExportPlatform, _debug: bool) -> String:
		var lines := PackedStringArray(["<queries>"])
		for category in ["android.intent.category.LAUNCHER", "android.intent.category.LEANBACK_LAUNCHER", "com.oculus.intent.category.VR"]:
			lines.append('<intent><action android:name="android.intent.action.MAIN"/><category android:name="%s"/></intent>' % category)
		for package_name in InstalledApps.SMARTTUBE_PACKAGES + ["com.brave.browser"]:
			lines.append('<package android:name="%s"/>' % package_name)
		lines.append("</queries>")
		return "\n".join(lines)
