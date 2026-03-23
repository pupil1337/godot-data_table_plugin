class_name TableRowBase
extends Object
## DataTable row structure, subclass declare @export variable to used


## Get the list of @export properties of the Script[br]
## return value type is same as the Object.get_property_list()
func get_script_variable_property_list() -> Array[Dictionary]:
	var res: Array[Dictionary] = []
	for i: Dictionary in get_property_list():
		if i["usage"] & PropertyUsageFlags.PROPERTY_USAGE_SCRIPT_VARIABLE:
			res.append(i)
	return res
