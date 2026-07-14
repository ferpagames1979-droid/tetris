# this class control the print of system (autoload)
# dev by: Ferpa Games

extends Node

const CLASS_NAME = "PrintLogManager"

var project_name = ProjectSettings.get_setting("application/config/name")

enum LogType { 
	DEBUG, 
	INFO, 
	ERROR, 
	WARNING, 
}

var _is_log_activate: bool = true

## className = name of class
## logType = type of log (LogType)
## message = message
func printlog(className: String, logType: LogType, message: String):
	if _is_log_activate:
		var format_string = "[%s][%s]: %s"
		var final_message = format_string % [className, _get_desc_log_type(logType), message]		
		
		if logType == LogType.ERROR:
			push_error(final_message) 
		elif logType == LogType.WARNING:
			push_warning(final_message)		
		print(final_message)


func _get_desc_log_type(logType: LogType) -> String:	
	match logType:
		LogType.DEBUG: return "DEBUG"
		LogType.INFO: return "INFO"
		LogType.ERROR: return "ERROR"
		LogType.WARNING: return "WARNING"
	return "UNKNOWN"
	
## clean log file
func clean_log_file() -> void:
	var arquivo = FileAccess.open("user://" + project_name + ".txt", FileAccess.WRITE)
	arquivo.store_string("")  
	arquivo.close()
	
## return node's name
func get_class_name_from_node(node: Node) -> String:
	return node.name
	
## return class_name 
func get_script_class_name(node: Node) -> String:
	var script = node.get_script()
	if script and script.get_global_name() != "":
		return script.get_global_name()
	return node.name  
