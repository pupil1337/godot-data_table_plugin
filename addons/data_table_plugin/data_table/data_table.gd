@tool @icon("res://addons/data_table_plugin/icons/GridContainer.svg")
class_name DataTable
extends Resource
## DataTable, as Resource save to filesystem


@warning_ignore_start("unsafe_cast")


## The script used for the table structure (must extend TableRowBase).
@export var table_row_script: GDScript

## storage_data[br]
## Store as Array and use the ResourceSaver.save to save.[br]
##   [ [ "RowName", { "PropertyName": Variant, ... } ], ... ]
@export_storage() var storage_datas: Array[Array] = []:
	set = _on_set_storage_datas

# inner
@export_storage() var _version: String = "1.0.0"
var _saving: bool = false

## data[br]
## [editor] Read from .tres[br]
##   { "RowName": { "PropertyName": Variant, ... }, ... } [br]
## [game] Red from .tres[br]
##   { "RowName": TableRowBase, ... }
@export_custom(PropertyHint.PROPERTY_HINT_NONE, "",\
	PropertyUsageFlags.PROPERTY_USAGE_EDITOR | PropertyUsageFlags.PROPERTY_USAGE_READ_ONLY)\
	var datas: Dictionary = {}:
		set = _on_set_datas


func _on_set_storage_datas(new_storage_datas: Array[Array]) -> void:
	# call from 1.@export init 2.saving
	storage_datas = new_storage_datas
	if _saving:
		return
	if Engine.is_editor_hint():
		for p_storage_data: Array in new_storage_datas:
			datas[p_storage_data[0]] = p_storage_data[1]
	else:
		if table_row_script == null:
			push_error(resource_path, " not set TableRowBase!")
			return
		if table_row_script.get_base_script() != DataTableTypes.table_row_base_script:
			push_error(resource_path, " set ", table_row_script.resource_path.get_file(), "not Inherit from TableRowBase!")
			return
		for p_storage_data: Array in new_storage_datas:
			var row_name: String = p_storage_data[0]
			var value: Dictionary = p_storage_data[1]
			if datas.has(row_name):
				push_error(resource_path, " RowName:", row_name, " appears more than once, needs modify.!")
				continue
			var obj: TableRowBase = table_row_script.new()
			for property: String in value:
				obj.set(property, value[property])
			datas[row_name] = obj


func _on_set_datas(new_datas: Dictionary) -> void:
	if _version == "1.0.0":
		var new_storage_datas: Array[Array] = []
		for row_name: String in new_datas:
			new_storage_datas.push_back([row_name, new_datas[row_name]])
		_on_set_storage_datas(new_storage_datas)
		if Engine.is_editor_hint():
			_version = DataTablePlugin.plugin_instance.get_plugin_version()
	else:
		datas = new_datas


# [only game]: free data objects cache
func _notification(what: int) -> void:
	if !Engine.is_editor_hint():
		if what == Object.NOTIFICATION_PREDELETE:
			for row_name: String in datas:
				(datas[row_name] as TableRowBase).free()
			datas.clear()


# when table_row_script is true, set table_row_script read-only
func _validate_property(property: Dictionary) -> void:
	if property["name"] == "table_row_script":
		if table_row_script != null && table_row_script.get_base_script() == DataTableTypes.table_row_base_script:
			property["usage"] |= PropertyUsageFlags.PROPERTY_USAGE_READ_ONLY


func save() -> void:
	if Engine.is_editor_hint():
		_saving = true
		var new_storage_datas: Array[Array] = []
		for row_name: String in datas:
			new_storage_datas.push_back([row_name, datas[row_name]])
		storage_datas = new_storage_datas
		ResourceSaver.save(self)
		_version = DataTablePlugin.plugin_instance.get_plugin_version()
		_saving = false


#region public
## Find Row by RowName[br]
## not find return null
func find_row(row_name: String, warn_if_row_missing: bool = true) -> TableRowBase:
	if !datas.has(row_name):
		if warn_if_row_missing:
			push_warning("DataTable::find_row: '%s' , not in DataTable '%s'" % [row_name, resource_path])
		return null
	return datas[row_name]


## Foreach row
## example: foreach_row(func (row: String, value: TableRowBase): print("row:%s, value:%s" % [row, value]))
func foreach_row(callback: Callable) -> void:
	for row_name: String in datas:
		callback.call(row_name, datas[row_name])
#endregion
