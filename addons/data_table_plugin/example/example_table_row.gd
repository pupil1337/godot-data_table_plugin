class_name ExampleTableRow
extends TableRowBase

## Test int
@export var test_int: int = 1
## Test float
@export var test_float: float = 2.0
## Text Vector2
@export var test_vector2: Vector2 = Vector2(3.0, 4.0)
## Text String
@export var test_string: String = "abc"
## Test PackedScene
@export var test_packed_scene: PackedScene


# Only for test! un-need override
func _to_string() -> String:
	return "<test_int:%d, test_float:%f, test_vector2:%s, test_string:%s, test_packed_scene:%s>" %\
			[test_int, test_float, test_vector2, test_string, test_packed_scene.resource_path.get_file() if test_packed_scene else "null"]
