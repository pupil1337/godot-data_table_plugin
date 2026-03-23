[中文](#godot-data_table_plugin) | [English](#godot-data_table_plugin-1)


# godot-data_table_plugin
数据表格插件，可以创建一个`Resource`类型的表格类，然后在godot中编辑它。


## 主要概念
**DataTable**: 一个`Resource`类型，在其中声明了一个`Dictionary`作为储存数据的变量  
**TableRowBase**: 一个`Object`类型，需要被用户继承并且需要在子类中声明`@export var`  

*运作原理就是`TableRowBase子类`定义了表结构，`DataTable`引用它。  
**序列化**：当在编辑器UI中增加一行Row的时候，会new一个`TableRowBase子类`对象，
然后其实例放入到`DataTable的data`中，当`ResourceSaver.save(DataTable)`时候引擎会自动序列化这个data。  
**反序列化**同理：遍历data创建定义的`TableRowBase`子类，用`var_to_str`将data的数据反序列化到`TableRowBase`实例中*  
**检查器面板**: 直接调用`EditorInterface.get_inspector().edit(Object)`即可编辑某个`Object`


## 用法
*首先需要在项目设置中开启本插件：Menu->Project->Project Settings->Plugins-> Enabled DataTablePlugin*
### 1. 在FileSystem中右键创建一个`Resource`，类型选择`DataTable`
![alt text](screenshot/image_create_new_resource.png)

### 2. 双击新创建的资源例如test_data_table.tres
![alt text](screenshot/image_open_empty_data_table.png)

### 3. 在FileSystem中再次右键创建一个`Script`，脚本类型继承自`TableRowBase`，例如test_table_row.gd
![alt text](screenshot/image_create_table_row_script.png)

### 4. 打开test_data_table.tres，设置其`属性TableRowScript`为刚刚创建的test_table_row.gd，并且保存
![alt text](screenshot/image_set_table_row_script.png)
![alt text](screenshot/image_open_data_table_with_empty_table_row.png)
至此，已经创建了一个DataTable并且其表格数据结构是空的(因为还未定义类型)。

### 5. 打开test_table_row.gd，定义一些`@export类型的变量`，并且保存
![alt text](screenshot/image_table_row_add_property.png)

### 6. 打开test_data_table.tres，会发现已经出现了表结构，并且可以点击"Add/Delete"按钮，也能编辑数据(编辑会实时保存到.tres文件中)
![alt text](screenshot/gif_create_row.gif)


## `DataTable`接口
```
func find_row(row_name: String, warn_if_row_missing: bool = true) -> TableRowBase
func foreach_row(callback: Callable) -> void
```




# godot-data_table_plugin
A data table plugin that allows you to create a `Resource` and edit it in godot.


## Main Concepts
**DataTable**: A `Resource` type that declare a `Dictionary` as the variable for storing data.  
**TableRowBase**: An `Object` type that needs to be inherited by the user, with `@export var` declared in the subclass.

*The operating principle is that the `TableRowBase subclass` defines the table structure, and `DataTable` references it.  
**Serialization**: When a row is added through the editor UI, a new `TableRowBase subclass` object is created and its instance is placed into the DataTable's data. When `ResourceSaver.save(DataTable)` is called, the engine automatically serializes this data.  
**Deserialization**: Similarly, it iterates through the data, creates the defined `TableRowBase subclas`s, and uses `var_to_str` to deserialize the data back into the `TableRowBase` instance.*  
**Inspector Panel**: Directly call `EditorInterface.get_inspector().edit(Object)` to edit a specific Object.


## Usage
*First, you need to enable this plugin in the project settings: Menu -> Project -> Project Settings -> Plugins -> Enabled DataTablePlugin*
### 1. Right-click in the FileSystem to create a new `Resource`, and select `DataTable` as the type.
![alt text](screenshot/image_create_new_resource.png)

### 2. Double-click the newly created resource, e.g., test_data_table.tres.
![alt text](screenshot/image_open_empty_data_table.png)

### 3. Right-click again in the FileSystem to create a new `Script`, with the script type `inheriting from TableRowBase`, e.g., test_table_row.gd.
![alt text](screenshot/image_create_table_row_script.png)

### 4. Open test_data_table.tres, set its `TableRowScript property` to the newly created test_table_row.gd, and save.
![alt text](screenshot/image_set_table_row_script.png)
![alt text](screenshot/image_open_data_table_with_empty_table_row.png)
At this point, you have created a DataTable with an empty table structure (since no fields have been defined yet).

### 5. Open test_table_row.gd, define some `@export variables`, and save.
![alt text](screenshot/image_table_row_add_property.png)

### 6. Open test_data_table.tres again, and you will see the table structure has appeared. You can now click the "Add/Delete" buttons and edit the data (editing will be saved to the .tres file in real-time).
![alt text](screenshot/gif_create_row.gif)


## `DataTable` Interface
```
func find_row(row_name: String, warn_if_row_missing: bool = true) -> TableRowBase
func foreach_row(callback: Callable) -> void
```