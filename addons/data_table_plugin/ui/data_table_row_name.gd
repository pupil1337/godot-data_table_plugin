@tool
class_name DataTableRowName
extends Container
## DataTable RowName UI


@onready var index_label: Label = $HBoxContainer/Label
@onready var row_name_text_edit: LineEdit = $HBoxContainer/TextEdit


# set row data
func set_row_data(row_info: DataTableTypes.UIRowNameInfo) -> float:
	index_label.text = str(row_info.index)
	row_name_text_edit.text = row_info.row_name
	return get_minimum_size().y


# set size.y
func set_row_name_size_y(size_y: float) -> void:
	row_name_text_edit.custom_minimum_size.y = size_y
