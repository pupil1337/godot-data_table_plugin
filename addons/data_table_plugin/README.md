# godot-data_table_plugin
数据表格插件，可以创建一个Resource类型的表格类，然后在godot中编辑它。


## 主要概念
**DataTable**: 一个Resource类型，在其中声明了一个Dictionary作为储存数据的变量  
**TableRowBase**: 一个Object类型，需要被用户继承并且需要在子类中声明@export var  

*运作原理就是TableRowBase子类定义了表结构，DataTable引用它。  
**序列化**：当在编辑器UI中增加一行Row的时候，会new一个TableRowBase子类对象，
然后其实例放入到DataTable的data中，当ResourceSaver.save(DataTable)时候引擎会自动序列化这个data。  
**反序列化**同理：遍历data创建定义的TableRowBase子类，用var_to_str将data的数据反序列化到TableRowBase实例中*  
**检查器面板**: 直接调用EditorInterface.get_inspector().edit(Object)即可编辑某个Object


## 用法
*首先需要在项目设置中开启本插件：Menu->Project->Project Settings->Plugins-> Enabled DataTablePlugin*
### 1. 在FileSystem中右键创建一个Resource，类型选择**DataTable**
![alt text](screenshot/image_create_new_resource.png)

### 2. 双击新创建的资源例如test_data_table.tres
![alt text](screenshot/image_open_empty_data_table.png)

### 3. 在FileSystem中再次右键创建一个Script，脚本类型继承自**TableRowBase**，例如test_table_row.gd
![alt text](screenshot/image_create_table_row_script.png)

### 4. 打开test_data_table.tres，设置其**属性TableRowScript**为刚刚创建的test_table_row.gd，并且保存
![alt text](screenshot/image_set_table_row_script.png)
![alt text](screenshot/image_open_data_table_with_empty_table_row.png)
至此，已经创建了一个DataTable并且其表格数据结构是空的(因为还未定义类型)。

### 5. 打开test_table_row.gd，定义一些**@export类型的变量**，并且保存
![alt text](screenshot/image_table_row_add_property.png)

### 6. 打开test_data_table.tres，会发现已经出现了表结构，并且可以点击"Add/Delete"按钮，也能编辑数据(编辑会实时保存到.tres文件中)
![alt text](screenshot/gif_create_row.gif)


## **DataTable**接口
```
func find_row(row_name: String, warn_if_row_missing: bool = true) -> TableRowBase
func foreach_row(callback: Callable) -> void
```