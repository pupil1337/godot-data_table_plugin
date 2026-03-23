@tool @icon("res://addons/data_table_plugin/icons/GridContainer.svg")
class_name DataTable
extends Resource
## DataTable, as Resource save to filesystem


@warning_ignore_start("unsafe_cast")


## The script used for the table structure (must extend TableRowBase).
@export var table_row_script: GDScript


## data[br]
## [editor]Store as a Dictionary and use the ResourceSaver.save to save.[br]
##  { "RowName": { "PropertyName": Variant, ... }, ... }[br]
## [game]When deserialize data, adjust the data structure to: { "RowName": TableRowBase, ... }
@export_custom(PropertyHint.PROPERTY_HINT_NONE, "",\
	PropertyUsageFlags.PROPERTY_USAGE_DEFAULT | PropertyUsageFlags.PROPERTY_USAGE_READ_ONLY)\
	var datas: Dictionary = {}:
		set = _on_set_datas


# [edotor]: do nothing
# [game]: adjust data types.
func _on_set_datas(new_datas: Dictionary) -> void:
	if Engine.is_editor_hint():
		datas = new_datas
	else:
		if table_row_script == null:
			push_error(resource_path, " not set TableRowBase!")
			return
		if table_row_script.get_base_script() != DataTableTypes.table_row_base_script:
			push_error(resource_path, " set ", table_row_script.resource_path.get_file(), "not Inherit from TableRowBase!")
			return
		for row_name: String in new_datas:
			if datas.has(row_name):
				push_error(resource_path, " RowName:", row_name, " appears more than once, needs modify.!")
				continue
			var obj: TableRowBase = table_row_script.new()
			for property: String in new_datas[row_name]:
				obj.set(property, new_datas[row_name][property])
			datas[row_name] = obj


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
