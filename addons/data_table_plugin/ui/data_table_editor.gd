@tool
class_name DataTableEditor
extends Control
## DataTable Editor UI, show in main screen


@warning_ignore_start("unsafe_cast")
@warning_ignore_start("return_value_discarded")
@warning_ignore_start("unused_parameter")


# adjust ui size success signal
signal _adjust_size_success


# Curr Editor UI State
enum EditorState
{
	WAIT_OPEN_FILE, # Wait Open File
	NOT_SET_ROW,	# Not Set TableRowBase
	EDITING,		# Editting
}


# tips string
const WAIT_OPEN_FILE_TEXT: String = "[color=pink]Double-click the table file in the file system to open.[/color]"
const NOT_SET_ROW_TEXT: String = "Please set [color=green]TableRowScript[/color] in Inspector."


# packed scene
var data_table_row_tscn: PackedScene = load("res://addons/data_table_plugin/ui/data_table_row.tscn")
var data_table_row_name_tscn: PackedScene = load("res://addons/data_table_plugin/ui/data_table_row_name.tscn")


# Curr Info
var curr_state: EditorState
var curr_data_table: DataTable
var curr_table_row_template_object: TableRowBase
var curr_table_row_info_list: Array[DataTableTypes.UIRowNameInfo]
var curr_table_col_info_list: Array[DataTableTypes.UIColInfo]
var curr_select_index: int = -1
var curr_edit_object: TableRowBase

# Temp
var property_scroll_v_last_frame: int
var row_name_property_scroll_v_last_frame: int
var last_adjust_size_call_frame: int
var dont_open_table_at_frame: int


# TableName
@onready var table_label: RichTextLabel = $VBoxContainer/CurrTableLabel
# TablePanel
@onready var table_panel: VBoxContainer = $VBoxContainer
# TipsLabel
@onready var tips_label: RichTextLabel = $TipsLabel


# RowName HBox
@onready var row_name_hbox: HBoxContainer = $VBoxContainer/Panel/HSplitRowName/HBoxRowName

# RowName|RowHeader Split
@onready var row_name_splite: HSplitContainer = $VBoxContainer/Panel/HSplitRowName

# RowHeader Scroll
@onready var row_head_scroll: ScrollContainer = $VBoxContainer/Panel/HSplitRowName/ScrollRowHeader
# RowHeader HBox
@onready var row_head_hbox: HBoxContainer = $VBoxContainer/Panel/HSplitRowName/ScrollRowHeader/HBoxRowHeader


# RowNameProperty Scroll
@onready var row_name_property_scroll: ScrollContainer = $VBoxContainer/Panel/HSplitProperty/ScrollRowNameProperty
# RowNameProperty VBox
@onready var row_name_property_vbox: VBoxContainer = $VBoxContainer/Panel/HSplitProperty/ScrollRowNameProperty/VBoxRowNameProperty

# RowNameProperty|RowProperty Split
@onready var row_name_property_splite: HSplitContainer = $VBoxContainer/Panel/HSplitProperty

# RowProperty Scroll
@onready var property_scroll: ScrollContainer = $VBoxContainer/Panel/HSplitProperty/ScrollRowProperty
# RowProperty VBox
@onready var property_vbox: VBoxContainer = $VBoxContainer/Panel/HSplitProperty/ScrollRowProperty/VBoxRowProperty


# 增加一行 按钮
@onready var add_row_btn: Button = $VBoxContainer/ScrollContainer/HBoxContainer/AddRowButton
# 删除此行 按钮
@onready var del_row_btn: Button = $VBoxContainer/ScrollContainer/HBoxContainer/DeleteRowButton
# 编辑.tres 按钮
@onready var default_property_btn: Button = $VBoxContainer/ScrollContainer/HBoxContainer/DefaultPropertyButton


func _ready() -> void:
	row_name_splite.dragged.connect(_on_dragged)
	add_row_btn.pressed.connect(_on_add_row_pressed)
	del_row_btn.pressed.connect(_on_del_row_pressed)
	default_property_btn.pressed.connect(_on_default_property_pressed)
	_set_state(EditorState.WAIT_OPEN_FILE)


func _process(delta: float) -> void:
	# scroll horizontal
	row_head_scroll.scroll_horizontal = property_scroll.scroll_horizontal
	row_head_hbox.position.x = property_vbox.position.x
	# scroll vertical
	if property_scroll.scroll_vertical != property_scroll_v_last_frame:
		row_name_property_scroll.scroll_vertical = property_scroll.scroll_vertical
	if row_name_property_scroll.scroll_vertical != row_name_property_scroll_v_last_frame:
		property_scroll.scroll_vertical = row_name_property_scroll.scroll_vertical
	property_scroll_v_last_frame = property_scroll.scroll_vertical
	row_name_property_scroll_v_last_frame = row_name_property_scroll.scroll_vertical
	row_name_property_vbox.position.y = property_vbox.position.y


func _exit_tree() -> void:
	_free_object()


#region public
# Open table
func on_open_data_table(data_table: DataTable) -> void:
	if dont_open_table_at_frame == Engine.get_process_frames():
		return
	# reset editor
	_reset_editor()
	
	# Check is Set TableRowScript
	if data_table.table_row_script == null:
		curr_data_table = data_table
		_set_state(EditorState.NOT_SET_ROW)
		return
	
	print("OpenDataTable: ", data_table.resource_path)
	_set_state(EditorState.EDITING)
	# table_label
	table_label.text = "CurrOpened: " + data_table.resource_path.get_base_dir() + "/"\
		+ "[color=cyan]" + data_table.resource_path.get_file() + "[/color]"
	# curr_data_table
	curr_data_table = data_table
	# curr_table_row_template_object
	curr_table_row_template_object = curr_data_table.table_row_script.new()
	# curr_table_col_info_list
	for i: Dictionary in curr_table_row_template_object.get_script_variable_property_list():
		curr_table_col_info_list.append(DataTableTypes.UIColInfo.new(i["name"] as String, i["type"] as Variant.Type))
		print(i)
	print("col num: ", curr_table_col_info_list.size())
	# Reset Split offset
	row_name_splite.split_offsets = [-999]
	row_name_property_splite.split_offsets = [-999]
	# add_row_btn
	add_row_btn.disabled = false
	# add RowHeader
	for col: DataTableTypes.UIColInfo in curr_table_col_info_list:
		var label: Label = Label.new()
		label.text = col.name
		label.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
		label.set_meta(&"property", col.name)
		label.mouse_filter = Control.MOUSE_FILTER_STOP
		label.tooltip_text = type_string(typeof(curr_table_row_template_object.get(col.name)))
		row_head_hbox.add_child(label)
		col.max_size_x = label.size.x
	# Reset write data(because TableRowBase @exprot property may changed)
	var new_datas: Dictionary = {}
	for i: String in curr_data_table.datas.keys():
		new_datas[i] = {}
		for j: DataTableTypes.UIColInfo in curr_table_col_info_list:
			new_datas[i][j.name] = (curr_data_table.datas[i] as Dictionary).get(j.name, curr_table_row_template_object.get(j.name))
	curr_data_table.datas = new_datas
	ResourceSaver.save(curr_data_table)
	# Deserialize data from .tres
	var index: int = 0
	for row_name: String in curr_data_table.datas:
		_add_row(index, row_name, curr_data_table.datas[row_name] as Dictionary)
		index += 1
	# default focus index 0
	await _adjust_size_success
	if curr_table_row_info_list.size() * curr_table_col_info_list.size() != 0:
		grab_focus_index(0)


# cancel edit table
func on_cancel_edit_table() -> void:
	match curr_state:
		EditorState.WAIT_OPEN_FILE:
			pass
		EditorState.NOT_SET_ROW:
			_reset_editor()
		EditorState.EDITING:
			on_edit_row_index(-1)


# focus row callback (dont call this fuc manually)
func on_edit_row_index(index: int, edit_null_if_negative_index: bool = false) -> void:
	# un-focus old
	if curr_select_index != -1:
		(property_vbox.get_children()[curr_select_index] as DataTableRow).set_unselected_by_focus_other()
	var old_object: TableRowBase = curr_edit_object
	# focus new
	curr_select_index = index
	if curr_select_index >= 0:
		curr_edit_object = curr_data_table.table_row_script.new()
		var data: Dictionary = curr_data_table.datas.values()[index]
		for i: DataTableTypes.UIColInfo in curr_table_col_info_list:
			curr_edit_object.set(i.name, data[i.name])
		EditorInterface.get_inspector().edit(curr_edit_object)
		del_row_btn.disabled = false
	else:
		del_row_btn.disabled = true
		if edit_null_if_negative_index:
			EditorInterface.get_inspector().edit(null)
	# delete old object
	if old_object:
		old_object.free()


# edit property callback
func on_property_edited(property: String) -> void:
	var new_value: Variant = curr_edit_object.get(property)
	# write to .tres
	curr_data_table.datas[curr_data_table.datas.keys()[curr_select_index]][property] = new_value
	ResourceSaver.save(curr_data_table)
	# update Row ui
	(property_vbox.get_child(curr_select_index) as DataTableRow).on_change_property(property, new_value)
	# update curr row max size.y
	var max_size_y: float = (row_name_property_vbox.get_child(curr_select_index) as DataTableRowName)\
		.row_name_text_edit.get_minimum_size().y # row_name_property
	for i: Label in (property_vbox.get_child(curr_select_index) as DataTableRow).hbox.get_children():
		max_size_y = max(max_size_y, i.get_minimum_size().y) # row_property
	# update curr col max size.x
	var edited_col_index: int = 0
	var max_size_x: float = 0
	for i: Label in (property_vbox.get_child(0) as DataTableRow).hbox.get_children():
		if i.get_meta(&"property") == property:
			for j: DataTableRow in property_vbox.get_children():
				max_size_x = max(max_size_x, (j.hbox.get_child(edited_col_index) as Label).get_minimum_size().x) # row_property
			break
		edited_col_index += 1
	max_size_x = max(max_size_x, (row_head_hbox.get_child(edited_col_index) as Label).get_minimum_size().x) # row_head
	# adjust size
	if max_size_y != curr_table_row_info_list[curr_select_index].max_size_y\
		|| max_size_x != curr_table_col_info_list[edited_col_index].max_size_x:
			curr_table_row_info_list[curr_select_index].max_size_y = max_size_y
			curr_table_col_info_list[edited_col_index].max_size_x = max_size_x
			await _adjust_size()


# Try Rename row name
func try_rename_row_name(old_row_name: String, new_row_name: String) -> bool:
	if new_row_name.is_empty():
		push_warning("DataTablePlugin: RowName cant empty")
		return false
	if new_row_name != old_row_name && curr_data_table.datas.has(new_row_name):
		push_warning("DataTablePlugin: RowName is exist")
		return false
	
	var new_dictionary: Dictionary = {}
	for key: String in curr_data_table.datas:
		if key == old_row_name:
			new_dictionary[new_row_name] = curr_data_table.datas[key]
		else:
			new_dictionary[key] = curr_data_table.datas[key]
	curr_data_table.datas = new_dictionary
	ResourceSaver.save(curr_data_table)
	return true


# grab one row && ensure visible
func grab_focus_index(index: int) -> void:
	var focus_row: DataTableRow = property_vbox.get_child(index) as DataTableRow
	var old_scroll_h: int = property_scroll.scroll_horizontal
	property_scroll.ensure_control_visible(focus_row)
	property_scroll.scroll_horizontal = old_scroll_h
	focus_row.btn.grab_focus()


# File System Changed callback
func on_filesystem_changed() -> void:
	if curr_data_table == null:
		return
	# curr opened .tres be deleted
	if curr_data_table.resource_path.is_empty():
		_reset_editor()
		EditorInterface.get_inspector().edit(null)
		return
	# curr opened .tres row struct changed(add/delete property || property type change)
	if curr_state == EditorState.EDITING:
		var new_row_obj: TableRowBase = curr_data_table.table_row_script.new()
		var new_property_list: Array[Dictionary] = new_row_obj.get_script_variable_property_list()
		var changed: bool = false
		if new_property_list.size() != curr_table_col_info_list.size():
			changed = true
		else:
			for i: int in new_property_list.size():
				if new_property_list[i]["name"] != curr_table_col_info_list[i].name\
				 || new_property_list[i]["type"] != curr_table_col_info_list[i].type:
					changed = true
					break
		new_row_obj.free()
		if changed:
			EditorInterface.get_inspector().edit(null)
			EditorInterface.get_inspector().edit(curr_data_table)
	# curr is NOT_SET_ROW state
	if curr_state == EditorState.NOT_SET_ROW:
		if curr_data_table.table_row_script != null:
			# set success
			if curr_data_table.table_row_script.get_base_script() == DataTableTypes.table_row_base_script:
				EditorInterface.get_inspector().edit(null)
				EditorInterface.get_inspector().edit(curr_data_table)
			# set failed
			else:
				curr_data_table.table_row_script = null
				ResourceSaver.save(curr_data_table)
				push_error(curr_data_table.resource_path.get_file(), " TableRowScript must Inherit from TableRowBase")
#endregion


#region private
# set curr state
func _set_state(new_state: EditorState) -> void:
	curr_state = new_state
	match curr_state:
		EditorState.WAIT_OPEN_FILE:
			table_panel.visible = false
			tips_label.visible = true
			tips_label.text = WAIT_OPEN_FILE_TEXT
		EditorState.NOT_SET_ROW:
			table_panel.visible = false
			tips_label.visible = true
			tips_label.text = NOT_SET_ROW_TEXT
		EditorState.EDITING:
			table_panel.visible = true
			tips_label.visible = false


# RowName Splite Drag callback
func _on_dragged(offset: int) -> void:
	row_name_property_splite.split_offsets = row_name_splite.split_offsets


# Add Row Pressed callback
func _on_add_row_pressed() -> void:
	# write to .tres
	var new_row_data: TableRowBase = curr_data_table.table_row_script.new()
	var new_row_name: String = str("RowName_", new_row_data.get_instance_id())
	curr_data_table.datas[new_row_name] = {}
	for i: DataTableTypes.UIColInfo in curr_table_col_info_list:
		curr_data_table.datas[new_row_name][i.name] = new_row_data.get(i.name)
	new_row_data.free()
	ResourceSaver.save(curr_data_table)
	# add row ui
	var new_index: int = curr_data_table.datas.size() - 1
	_add_row(new_index, new_row_name, curr_data_table.datas[new_row_name] as Dictionary)
	# focus new row ui
	var new_row: DataTableRow = (property_vbox.get_child(new_index) as DataTableRow)
	new_row.btn.grab_focus()
	await _adjust_size_success
	grab_focus_index(new_index)


# Delete Row Pressed callback
func _on_del_row_pressed() -> void:
	if curr_select_index == -1:
		return
	# write to .tres
	curr_data_table.datas.erase(curr_data_table.datas.keys()[curr_select_index])
	ResourceSaver.save(curr_data_table)
	# remove ui
	var row_name: DataTableRowName = row_name_property_vbox.get_child(curr_select_index) as DataTableRowName
	row_name_property_vbox.remove_child(row_name)
	row_name.queue_free()
	var row_property: DataTableRow = property_vbox.get_child(curr_select_index) as DataTableRow
	property_vbox.remove_child(row_property)
	row_property.queue_free()
	# delete row info_list
	(curr_table_row_info_list.pop_at(curr_select_index) as DataTableTypes.UIRowNameInfo).free()
	# sync row_index change
	for i: int in curr_table_row_info_list.size():
		(property_vbox.get_child(i) as DataTableRow).row_index = i
	for i: int in curr_table_row_info_list.size():
		(row_name_property_vbox.get_child(i) as DataTableRowName).index_label.text = str(i)
	# cancel focus curr row && auto select up/down
	var old_index: int = curr_select_index
	curr_select_index = -1
	var new_child_count: int = curr_table_row_info_list.size()
	if new_child_count == 0:
		on_edit_row_index(-1, true)
	else:
		grab_focus_index(clampi(old_index, 0, new_child_count - 1))
	# update all col max size.x
	var col_max_size_x: Array[float] = []
	for i: Label in row_head_hbox.get_children():
		col_max_size_x.append(i.get_minimum_size().x)
	for i: DataTableRow in property_vbox.get_children():
		var index: int = 0;
		for j: Label in i.hbox.get_children():
			col_max_size_x[index] = max(col_max_size_x[index], j.get_minimum_size().x)
			index += 1
	var need_adjust: bool = false
	for i: int in col_max_size_x.size():
		if curr_table_col_info_list[i].max_size_x != col_max_size_x[i]:
			curr_table_col_info_list[i].max_size_x = col_max_size_x[i]
			need_adjust = true
	if need_adjust:
		await _adjust_size()


# Default .tres Property Pressed callback
func _on_default_property_pressed() -> void:
	dont_open_table_at_frame = Engine.get_process_frames()
	on_edit_row_index(-1)
	EditorInterface.get_inspector().edit(curr_data_table)


# add row
func _add_row(index: int, row_name: String, datas: Dictionary = {}) -> void:
	# RowName add one
	var data_table_row_name_info: DataTableTypes.UIRowNameInfo = DataTableTypes.UIRowNameInfo.new(index, row_name)
	curr_table_row_info_list.append(data_table_row_name_info)
	var data_table_row_name: DataTableRowName = data_table_row_name_tscn.instantiate()
	row_name_property_vbox.add_child(data_table_row_name)
	data_table_row_name.owner = self
	data_table_row_name_info.max_size_y = data_table_row_name.set_row_data(data_table_row_name_info)
	# Property add one
	if curr_table_col_info_list.size() > 0:
		var data_table_row: DataTableRow = data_table_row_tscn.instantiate()
		property_vbox.add_child(data_table_row)
		data_table_row.owner = self
		data_table_row.init_row_data(curr_table_row_template_object, data_table_row_name_info, curr_table_col_info_list, datas)
	# adjust_size deferred
	if last_adjust_size_call_frame != Engine.get_process_frames():
		last_adjust_size_call_frame = Engine.get_process_frames()
		_adjust_size.call_deferred()


# adjust Row/Col size
func _adjust_size() -> void:
	var index: int = 0
	# RowHeader
	index = 0
	for label: Label in row_head_hbox.get_children():
		label.custom_minimum_size.x = curr_table_col_info_list[index].max_size_x
		index += 1
	# RowNameProperty
	index = 0
	for row_name_property: DataTableRowName in row_name_property_vbox.get_children():
		row_name_property.set_row_name_size_y(curr_table_row_info_list[index].max_size_y)
		index += 1
	# RowProperty
	index = 0
	for data_table_row: DataTableRow in property_vbox.get_children():
		data_table_row.set_property_size(curr_table_row_info_list[index], curr_table_col_info_list)
		index += 1
	await get_tree().process_frame
	_adjust_size_success.emit()


# reset editor ui
func _reset_editor() -> void:
	# curr_state
	_set_state(EditorState.WAIT_OPEN_FILE)
	# curr_select_index
	curr_select_index = -1
	# free object
	_free_object()


# free object
func _free_object() -> void:
	# curr_data_table
	curr_data_table = null
	# curr_table_row_template_object
	if curr_table_row_template_object:
		curr_table_row_template_object.free()
	curr_table_row_template_object = null
	# curr_table_row_info_list
	for i: DataTableTypes.UIRowNameInfo in curr_table_row_info_list:
		i.free()
	curr_table_row_info_list.clear()
	# curr_table_col_info_list
	for i: DataTableTypes.UIColInfo in curr_table_col_info_list:
		i.free()
	curr_table_col_info_list.clear()
	# curr_edit_object
	if curr_edit_object:
		curr_edit_object.free()
	curr_edit_object = null
	# row_head_hbox
	for i: Label in row_head_hbox.get_children():
		row_head_hbox.remove_child(i)
		i.queue_free()
	# row_name_property_vbox
	for i: DataTableRowName in row_name_property_vbox.get_children():
		row_name_property_vbox.remove_child(i)
		i.queue_free()
	# property_vbox
	for i: DataTableRow in property_vbox.get_children():
		property_vbox.remove_child(i)
		i.queue_free()
#endregion
