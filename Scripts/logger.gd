extends Node

const DEFAULT_LOG_PATH: String = "user://"
const DEFAULT_LOG_NAME: String = "LOGGER"

func get_logger(script_name):
	return Log.new(script_name)

class Log:
	var info_logging = true
	var debug_logging = true
	var warn_logging = true
	var error_logging = true
	
	var script_name = ""
	var current_function_name = ""
	
	func set_script_name(new_script_name: String) -> void:
		script_name = new_script_name
	
	func _init(new_script_name: String) -> void:
		set_script_name(new_script_name)
	
	func start(function_name: String) -> void:
		current_function_name = function_name
	
	func end() -> void:
		current_function_name = ""
	
	func info(message: String, function_name: String) -> void:
		if info_logging:
			var level = "INFO "
			_log(level, message, function_name)
	
	func debug(message: String, function_name: String) -> void:
		if debug_logging:
			var level = "INFO "
			_log(level, message, function_name)
	
	func warn(message: String, function_name: String) -> void:
		if warn_logging:
			var level = "WARN "
			_log(level, message, function_name)
	
	func error(message: String, function_name: String) -> void:
		if error_logging:
			var level = "ERROR "
			_log(level, message, function_name)
	
	func _log(level: String, message: String, function_name: String) -> void:
		if function_name.is_empty():
			function_name = current_function_name
		var log_message: String =  _get_current_time() + " | " + level + " | " + "[" + self.script_name + "]" + " [" + function_name + "] " + ">> " + message
		var file_name: String = DEFAULT_LOG_PATH + Time.get_date_string_from_system() + DEFAULT_LOG_NAME + ".log"
		if FileAccess.file_exists(file_name):
			var file = FileAccess.open(file_name, FileAccess.READ_WRITE)
			file.seek_end()
			file.store_line(log_message)
		else:
			var file = FileAccess.open(file_name, FileAccess.WRITE)
			file.store_line("        TIME        | LEVEL | SCRIPT | FUNCTION | MESSAGE")
			file.store_line(log_message)
	
	func _get_current_time() -> String:
		return Time.get_datetime_string_from_system()
