@tool
class_name DataTableRow
extends CenterContainer
## DataTable Row UI


@warning_ignore_start("return_value_discarded")


@onready var btn: Button = $Button
@onready var hbox: HBoxContainer = $Button/HBoxContainer


# style
static var grey_bg: StyleBoxFlat = StyleBoxFlat.new()
static var white_bg: StyleBoxFlat = StyleBoxFlat.new()
var btn_normal_style: StyleBoxEmpty = StyleBoxEmpty.new()
var btn_pressed_style: StyleBoxFlat = StyleBoxFlat.new()
var btn_hover_style: StyleBoxFlat = StyleBoxFlat.new()
var btn_focus_style: StyleBoxFlat = StyleBoxFlat.new()


var row_index: int = -1


static func _static_init() -> void:
	# grey_bg
	grey_bg.bg_color = Color(0.2, 0.2, 0.2)
	# white_bg
	white_bg.bg_color = Color(0.8, 0.8, 0.8)


func _ready() -> void:
	btn_normal_style = btn.get_theme_stylebox(&"normal")
	btn_pressed_style = btn.get_theme_stylebox(&"pressed")
	btn_hover_style = btn.get_theme_stylebox(&"hover")
	btn_focus_style = btn.get_theme_stylebox(&"focus")
	
	btn.focus_entered.connect(_on_btn_focus_entered)
	btn.gui_input.connect(_on_btn_gui_input)


# When focused, limit focus within the vertical box.
func _on_btn_gui_input(event: InputEvent) -> void:
	var key_event: InputEventKey = event as InputEventKey
	if key_event && key_event.pressed:
		var property_scroll: ScrollContainer = (owner as DataTableEditor).property_scroll
		var old_property_scroll_h: int = property_scroll.scroll_horizontal
		var property_vbox: VBoxContainer = (owner as DataTableEditor).property_vbox
		match key_event.keycode:
			Key.KEY_LEFT:
				property_scroll.scroll_horizontal = old_property_scroll_h - 10
				get_viewport().set_input_as_handled()
			Key.KEY_RIGHT:
				property_scroll.scroll_horizontal = old_property_scroll_h + 10
				get_viewport().set_input_as_handled()
			Key.KEY_UP:
				if row_index != 0:
					(owner as DataTableEditor).grab_focus_index(row_index - 1)
				get_viewport().set_input_as_handled()
			Key.KEY_DOWN:
				if row_index != property_vbox.get_child_count() - 1:
					(owner as DataTableEditor).grab_focus_index(row_index + 1)
				get_viewport().set_input_as_handled()
			Key.KEY_DELETE:
				get_viewport().set_input_as_handled()
				await (owner as DataTableEditor)._on_del_row_pressed()


# init row data
func init_row_data(row_templete_object: Object, row_info: DataTableTypes.UIRowNameInfo, col_info_list: Array[DataTableTypes.UIColInfo], datas: Dictionary = {}) -> void:
	row_index = row_info.index
	var i: int = 0
	for col: DataTableTypes.UIColInfo in col_info_list:
		# label
		var label: Label = Label.new()
		if datas.has(col.name):
			label.text = var_to_str(datas.get(col.name))
		else:
			label.text = var_to_str(row_templete_object.get(col.name))
		label.add_theme_color_override(&"font_color", Color(1.0, 1.0, 1.0) if i % 2 else Color(0.0, 0.0, 0.0))
		label.add_theme_stylebox_override(&"normal", grey_bg if i % 2 else white_bg)
		label.set_meta(&"property", col.name)
		label.mouse_filter = Control.MOUSE_FILTER_PASS
		label.tooltip_text = col.name + ": " + label.text
		hbox.add_child(label)
		
		# property y
		row_info.max_size_y = max(row_info.max_size_y, label.get_minimum_size().y)
		# property x
		col.max_size_x = max(col.max_size_x, label.get_minimum_size().x)
		
		i += 1


# set property size
func set_property_size(row_info: DataTableTypes.UIRowNameInfo, col_info_list: Array[DataTableTypes.UIColInfo]) -> void:
	var index: int = 0
	for i: Label in hbox.get_children():
		i.custom_minimum_size.y = row_info.max_size_y
		i.custom_minimum_size.x = col_info_list[index].max_size_x
		index += 1
	btn.custom_minimum_size = hbox.get_minimum_size()


# change property callback
func on_change_property(property: String, new_value: Variant) -> void:
	for label: Label in hbox.get_children():
		if label.get_meta(&"property") == property:
			label.text = var_to_str(new_value)
			break


# focus callback
func _on_btn_focus_entered() -> void:
	btn.add_theme_stylebox_override(&"normal", btn_focus_style)
	btn.add_theme_stylebox_override(&"hover", btn_focus_style)
	
	(owner as DataTableEditor).on_edit_row_index(row_index)


# set un-focus
func set_unselected_by_focus_other() -> void:
	btn.add_theme_stylebox_override(&"normal", btn_normal_style)
	btn.add_theme_stylebox_override(&"hover", btn_hover_style)
