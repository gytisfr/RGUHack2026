# Kernel.gd
# Autoload singleton — add this in Project > Project Settings > Autoload
# Name it exactly: Kernel
extends Node

# ── In-memory filesystem ──────────────────────────────────────────────────────
# Structure: { "/path": null (file) or {} (dir), ... }
# File contents stored separately in _file_data
var _fs: Dictionary = {
	"/": {},
	"/home": {},
	"/home/user": {},
}
var _file_data: Dictionary = {}  # "/path" -> String content
var cwd: String = "/home/user"

# ── Signals ───────────────────────────────────────────────────────────────────
signal script_output(text: String)   # emitted when a script prints something
signal fs_changed()                  # emitted when filesystem is modified


# ── Path helpers ──────────────────────────────────────────────────────────────
func resolve(path: String) -> String:
	if path == "~":
		return "/home/user"
	if path.begins_with("/"):
		return _normalize(path)
	return _normalize(cwd.path_join(path))


func _normalize(path: String) -> String:
	var parts = path.split("/", false)
	var out: Array = []
	for p in parts:
		if p == "..":
			if out.size() > 0:
				out.pop_back()
		elif p != ".":
			out.append(p)
	return "/" + "/".join(out)


func is_dir(path: String) -> bool:
	return _fs.has(path) and _fs[path] is Dictionary


func is_file(path: String) -> bool:
	return _fs.has(path) and _fs[path] == null


func exists(path: String) -> bool:
	return _fs.has(path)


# ── Filesystem operations ─────────────────────────────────────────────────────
func mkdir(path: String) -> String:
	var p = resolve(path)
	if exists(p):
		return "mkdir: %s: already exists" % p
	var parent = p.get_base_dir()
	if not is_dir(parent):
		return "mkdir: %s: No such directory" % parent
	_fs[p] = {}
	fs_changed.emit()
	return ""


func touch(path: String) -> String:
	var p = resolve(path)
	if exists(p):
		return ""  # already exists, no-op
	var parent = p.get_base_dir()
	if not is_dir(parent):
		return "touch: %s: No such directory" % parent
	_fs[p] = null
	_file_data[p] = ""
	fs_changed.emit()
	return ""


func read_file(path: String) -> String:
	var p = resolve(path)
	if not is_file(p):
		return ""
	return _file_data.get(p, "")


func write_file(path: String, content: String) -> String:
	var p = resolve(path)
	if is_dir(p):
		return "write: %s: Is a directory" % p
	var parent = p.get_base_dir()
	if not is_dir(parent):
		return "write: %s: No such directory" % parent
	_fs[p] = null
	_file_data[p] = content
	fs_changed.emit()
	return ""


func rm(path: String) -> String:
	var p = resolve(path)
	if not exists(p):
		return "rm: %s: No such file or directory" % p
	_fs.erase(p)
	_file_data.erase(p)
	fs_changed.emit()
	return ""


func ls(path: String = "") -> Array:
	var target = resolve(path) if path != "" else cwd
	if not is_dir(target):
		return []
	var results: Array = []
	for key in _fs.keys():
		var parent = key.get_base_dir()
		if parent == target and key != target:
			var name = key.get_file()
			results.append({ "name": name, "is_dir": is_dir(key) })
	return results


# ── PicoS Script Runner ───────────────────────────────────────────────────────
# Supports a tiny scripting language:
#   print "hello"
#   set x 5
#   if $x == 5 then print "yes"
#   write /path/to/file "content"
#   read /path/to/file
#   mkdir /path
#   touch /path/file
#   for i in 1..5 do print $i
# Variables stored in _vars dict

var _vars: Dictionary = {}

func run_script(source: String) -> void:
	_vars = {}
	var lines = source.split("\n")
	var output: Array = []
	var i = 0
	while i < lines.size():
		var line = lines[i].strip_edges()
		if line == "" or line.begins_with("#"):
			i += 1
			continue
		var result = _exec_line(line, output)
		if result != "":
			output.append(result)
		i += 1
	script_output.emit("\n".join(output) if output.size() > 0 else "(script finished with no output)")


func _exec_line(line: String, output: Array) -> String:
	# Substitute variables like $varname
	var tokens = _tokenize(line)
	if tokens.is_empty():
		return ""
	
	var cmd = tokens[0].to_lower()
	var args = tokens.slice(1)
	
	match cmd:
		"print":
			var text = " ".join(args)
			output.append(_subst_vars(text))
			return ""
		
		"set":
			if args.size() < 2:
				return "set: usage: set <name> <value>"
			_vars[args[0]] = _subst_vars(" ".join(args.slice(1)))
			return ""
		
		"echo":
			output.append(_subst_vars(" ".join(args)))
			return ""
		
		"write":
			if args.size() < 2:
				return "write: usage: write <path> <content>"
			var content = _subst_vars(" ".join(args.slice(1))).trim_prefix('"').trim_suffix('"')
			return write_file(args[0], content)
		
		"read":
			if args.size() < 1:
				return "read: usage: read <path>"
			var content = read_file(args[0])
			output.append(content if content != "" else "(empty)")
			return ""
		
		"mkdir":
			if args.size() < 1:
				return "mkdir: missing path"
			return mkdir(args[0])
		
		"touch":
			if args.size() < 1:
				return "touch: missing path"
			return touch(args[0])
		
		"ls":
			var path = args[0] if args.size() > 0 else ""
			var entries = ls(path)
			if entries.is_empty():
				output.append("(empty)")
			else:
				var names: Array = []
				for e in entries:
					names.append(e["name"] + ("/" if e["is_dir"] else ""))
				output.append("  ".join(names))
			return ""
		
		"cd":
			if args.size() < 1:
				cwd = "/home/user"
				return ""
			var target = resolve(args[0])
			if not is_dir(target):
				return "cd: %s: No such directory" % target
			cwd = target
			return ""
		
		"if":
			# if $x == 5 then print "something"
			var then_idx = args.find("then")
			if then_idx == -1:
				return "if: missing 'then'"
			var condition = args.slice(0, then_idx)
			var body = args.slice(then_idx + 1)
			if _eval_condition(condition):
				return _exec_line(" ".join(body), output)
			return ""
		
		"for":
			# for i in 1..5 do print $i
			var in_idx = args.find("in")
			var do_idx = args.find("do")
			if in_idx == -1 or do_idx == -1:
				return "for: usage: for <var> in <start>..<end> do <cmd>"
			var var_name = args[0]
			var range_str = args[in_idx + 1]
			var body = args.slice(do_idx + 1)
			var parts = range_str.split("..")
			if parts.size() != 2:
				return "for: invalid range"
			var start = int(parts[0])
			var end_val = int(parts[1])
			for n in range(start, end_val + 1):
				_vars[var_name] = str(n)
				_exec_line(" ".join(body), output)
			return ""
		
		_:
			return "picos: %s: command not found" % cmd


func _subst_vars(text: String) -> String:
	for key in _vars.keys():
		text = text.replace("$" + key, _vars[key])
	return text


func _eval_condition(tokens: Array) -> bool:
	if tokens.size() < 3:
		return false
	var left = _subst_vars(tokens[0])
	var op = tokens[1]
	var right = _subst_vars(tokens[2])
	match op:
		"==": return left == right
		"!=": return left != right
		">":  return float(left) > float(right)
		"<":  return float(left) < float(right)
		">=": return float(left) >= float(right)
		"<=": return float(left) <= float(right)
	return false


func _tokenize(line: String) -> Array:
	var tokens: Array = []
	var current = ""
	var in_quote = false
	for ch in line:
		if ch == '"':
			in_quote = !in_quote
			current += ch
		elif ch == ' ' and not in_quote:
			if current != "":
				tokens.append(current)
				current = ""
		else:
			current += ch
	if current != "":
		tokens.append(current)
	return tokens
