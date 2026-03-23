@tool
extends EditorPlugin
## DataTable Plugin


@warning_ignore_start("return_value_discarded")


## DataTable Editor UI
var data_table_editor: DataTableEditor


func _enter_tree() -> void:
	# add editor ui
	data_table_editor = (load("res://addons/data_table_plugin/ui/data_table_editor.tscn") as PackedScene).instantiate()
	data_table_editor.visible = false
	EditorInterface.get_editor_main_screen().add_child(data_table_editor)
	# inspector signals
	EditorInterface.get_inspector().edited_object_changed.connect(_on_editor_inspector_edited_object_changed)
	EditorInterface.get_inspector().property_edited.connect(_on_editor_inspector_property_edited)
	# filesystem signals
	EditorInterface.get_resource_filesystem().filesystem_changed.connect(_on_filesystem_changed)


func _exit_tree() -> void:
	# set inspector edit null
	EditorInterface.get_inspector().edit(null)
	# remove editor ui
	EditorInterface.get_editor_main_screen().remove_child(data_table_editor)
	data_table_editor.queue_free()
	# inspector signals
	EditorInterface.get_inspector().edited_object_changed.disconnect(_on_editor_inspector_edited_object_changed)
	EditorInterface.get_inspector().property_edited.disconnect(_on_editor_inspector_property_edited)
	# filesystem signals
	EditorInterface.get_resource_filesystem().filesystem_changed.disconnect(_on_filesystem_changed)


func _has_main_screen() -> bool:
	return true


func _make_visible(visible: bool) -> void:
	data_table_editor.visible = visible


func _get_plugin_name() -> String:
	return "Data Table"


func _get_plugin_icon() -> Texture2D:
	return load("res://addons/data_table_plugin/icons/GridContainer.svg")


#region EditorPlugin
# Inspector edited_object_changed callback
func _on_editor_inspector_edited_object_changed() -> void:
	var edited_object: Object = EditorInterface.get_inspector().get_edited_object()
	if edited_object:
		if edited_object is DataTable:
			# edit DataTable -> Open Editor UI
			EditorInterface.set_main_screen_editor(_get_plugin_name())
			await data_table_editor.on_open_data_table(edited_object as DataTable)
		elif !(edited_object is TableRowBase):
			# !DataTable && !TableRowBase -> cancel_edit_table
			data_table_editor.on_cancel_edit_table()


# Inspector property_edited callback
func _on_editor_inspector_property_edited(property: String) -> void:
	var edited_object: Object = EditorInterface.get_inspector().get_edited_object()
	if edited_object is TableRowBase:
		await data_table_editor.on_property_edited(property)


# Filesystem changed callback
func _on_filesystem_changed() -> void:
	data_table_editor.on_filesystem_changed()
#endregion
