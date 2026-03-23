@tool
class_name DataTableTypes
extends Node
## Define DataTablePlugin Types


## TableRowBase GDScript ref
static var table_row_base_script: GDScript = load("res://addons/data_table_plugin/data_table/table_row_base.gd")


## DataTable UI col info
class UIColInfo extends Object:
	func _init(in_name: String, in_type: Variant.Type) -> void:
		name = in_name
		type = in_type
	var name: String # property name
	var type: Variant.Type # type
	var max_size_x: float # curr col max size.x


## DataTable UI row info
class UIRowNameInfo extends Object:
	func _init(in_index: int, in_row_name: String) -> void:
		index = in_index
		row_name = in_row_name
	var index: int # row index
	var row_name: String # row name
	var max_size_y: float # curr row max size.y
