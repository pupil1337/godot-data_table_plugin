extends Node


# test DataTable
var test_data_table: DataTable = load("res://addons/data_table_plugin/example/plugin_example_data_table.tres")


func _ready() -> void:
	print("Search\"1\":------")
	print(test_data_table.find_row("1"))
	print("Search\"no_exist\" with warn_if_row_missing:------")
	print(test_data_table.find_row("no_exist"))
	print("Search\"no_exist\" without warn_if_row_missing:------")
	print(test_data_table.find_row("no_exist", false))
	print("Foreach-----------------------")
	test_data_table.foreach_row(func (row_name: String, value: ExampleTableRow) -> void:
		print("row:%s, value:%s" % [row_name, value.to_string()]))
