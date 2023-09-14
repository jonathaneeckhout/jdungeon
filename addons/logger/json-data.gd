class_name JsonData

const REQUIRED_OBJECT_SUFFIX="_r"
const COMPACT_VAR_SUFFIX="_c"

const WHITELIST_VAR_NAME = "whitelist"

static func marshal(obj:Object,compact:bool=false,compressMode:int=-1,skip_whitelist:bool=false) -> PackedByteArray:
	if obj == null:
		return PackedByteArray()
	if compressMode == -1:
		return var_to_bytes(to_dict(obj,compact,skip_whitelist))
	return var_to_bytes(to_dict(obj,compact,skip_whitelist)).compress(compressMode)

static func unmarshal(dict:Dictionary,obj:Object,compressMode:int=-1) -> bool:
	if dict.size() == 0 or obj == null:
		return false
	for k in dict:
		if !k in obj:
			continue
		var newVar = _get_var(obj[k],dict[k])
		if newVar != null:
			if k == "name" && newVar == "":
				continue
			obj[k] = newVar
	return true

static func unmarshal_bytes_to_dict(data:PackedByteArray,compressMode:int=-1) -> Dictionary:
	if data.size() == 0:
		return {}
	if compressMode == -1:
		return bytes_to_var(data)
	return bytes_to_var(data.decompress_dynamic(-1,compressMode))

static func unmarshal_bytes(data:PackedByteArray,obj:Object,compressMode:int=-1) -> bool:
	if data.size() == 0 or obj == null:
		return false
	var dict = unmarshal_bytes_to_dict(data,compressMode)
	for k in dict:
		if !k in obj:
			continue
		var newVar = _get_var(obj[k],dict[k])
		if newVar != null:
			obj[k] = newVar
	return false

static func to_dict(obj:Object,compact:bool,skip_whitelist:bool=false) ->Dictionary:
	if obj == null:
		return {}
	if !skip_whitelist:
		return _get_dict_with_list(obj,obj.get_property_list(),compact)

	var output:Dictionary = {}
	if WHITELIST_VAR_NAME in obj and obj[WHITELIST_VAR_NAME].size() > 0:
		return _get_dict_with_list(obj,obj[WHITELIST_VAR_NAME],false)

	return output

static func required_items(property_list:Array) ->Array:
		var output:Array = []
		for property in property_list:
			var name = ""
			if typeof(property) != TYPE_STRING && "name" in property:
				name = str(property.name)
			else:
				name = property
			if _ends_with(name,[COMPACT_VAR_SUFFIX,REQUIRED_OBJECT_SUFFIX]):
				output.append(property)
				continue
		return output

static func _get_dict_with_list(obj:Object,property_list:Array,compact:bool) ->Dictionary:
	var output:Dictionary = {}
	for property in property_list:
		var name = ""
		if typeof(property) != TYPE_STRING && "name" in property:
			name = str(property.name)
		else:
			name = property
		if name.begins_with("_"):
			continue
		if compact and !_ends_with(name,[COMPACT_VAR_SUFFIX,REQUIRED_OBJECT_SUFFIX]):
			continue
		if !name in obj:
			continue
		var data_type = typeof(obj[name])
		var value = obj[name]
		match data_type:
			TYPE_NIL:
				continue
			TYPE_OBJECT:
				if _ends_with(name,[COMPACT_VAR_SUFFIX,REQUIRED_OBJECT_SUFFIX]):
					#var t = Thread.new()
					#var lamda = func():
					output[name] = to_dict(value,compact)

			TYPE_ARRAY: # todo
				continue
			TYPE_DICTIONARY: # todo
				var processsed_dictionary = {}
				for key in Dictionary(value):
					var key_type = typeof(value[key])
					var key_value = value[key]
					match key_type:
						TYPE_OBJECT:
							if _ends_with(name,[COMPACT_VAR_SUFFIX,REQUIRED_OBJECT_SUFFIX]):
								processsed_dictionary[name] = to_dict(key_value,compact)
						TYPE_ARRAY:
							continue
						_:
							processsed_dictionary[key] = key_value
				output[name] = processsed_dictionary
			_:
				output[name] = value
	return output

static func _ends_with(v:String,list:Array) -> bool:
	for s in list:
		if v.ends_with(s):
			return true
	return false

static func _get_var(expected,actual):
	if typeof(expected) == typeof(actual):
		return actual
	match typeof(expected):
		TYPE_NIL : # 0
			return null
		TYPE_BOOL : # 1
			return actual as bool
		TYPE_INT : # 2
			return actual as int
		TYPE_FLOAT : # 3
			return actual as float
		TYPE_STRING : # 4
			return actual
		TYPE_VECTOR2 : # 5
			var d = str(actual).substr(1,actual.size()-1).split_floats(",",false)
			if d.size() < 2:
				return null
			return Vector2(d[0],d[1])
		#return actual as Vector2
		TYPE_VECTOR2I : # 6
			var d = str(actual).substr(1,actual.size()-1).split_floats(",",false)
			if d.size() < 2:
				return null
			return Vector2i(Vector2(d[0],d[1]))
		TYPE_RECT2 : # 7
			var d = str(actual).substr(1,actual.size()-1).split_floats(",",false)
			if d.size() < 4:
				return null
			return Rect2(d[0],d[1],d[2],d[3])
		TYPE_RECT2I : # 8
			var d = str(actual).substr(1,actual.size()-1).split_floats(",",false)
			if d.size() < 4:
				return null
			return Rect2i(Rect2(d[0],d[1],d[2],d[3]))
		TYPE_VECTOR3 : # 9
			var d = str(actual).substr(1,actual.size()-1).split_floats(",",false)
			if d.size() < 3:
				return null
			return Vector3(d[0],d[1],d[2])
		TYPE_VECTOR3I : # 10
			var d = str(actual).substr(1,actual.size()-1).split_floats(",",false)
			if d.size() < 3:
				return null
			return Vector3i(Vector3(d[0],d[1],d[2]))
		TYPE_TRANSFORM2D : # 11
			return null
		TYPE_VECTOR4 : # 12
			return null
		TYPE_VECTOR4I : # 13
			return null
		TYPE_PLANE : # 14
			return null
		TYPE_QUATERNION : # 15
			return null
		TYPE_AABB : # 16
			return null
		TYPE_BASIS : # 17
			return null
		TYPE_TRANSFORM3D : # 18
			return null
		TYPE_PROJECTION : # 19
			return null
		TYPE_COLOR : # 20
			var d = str(actual).substr(1,actual.size()-1).split_floats(",",false)
			if d.size() < 4:
				return null
			return Color(d[0],d[1],d[2],d[3])
		TYPE_STRING_NAME : # 21
			return null
		TYPE_NODE_PATH : # 22
			return null
		TYPE_RID : # 23
			return null
		TYPE_OBJECT : # 24
			if unmarshal(actual as Dictionary,expected):
				return expected
			return null
		TYPE_CALLABLE : # 25
			return null
		TYPE_SIGNAL : # 26
			return null
		TYPE_DICTIONARY : # 27
			return JSON.parse_string(actual)
		TYPE_ARRAY : # 28
			return JSON.parse_string(actual)
		TYPE_PACKED_BYTE_ARRAY : # 29
			return null
		TYPE_PACKED_INT32_ARRAY : # 30
			return null
		TYPE_PACKED_INT64_ARRAY : # 31
			return null
		TYPE_PACKED_FLOAT32_ARRAY : # 32
			return null
		TYPE_PACKED_FLOAT64_ARRAY : # 33
			return null
		TYPE_PACKED_STRING_ARRAY : # 34
			return null
		TYPE_PACKED_VECTOR2_ARRAY : # 35
			return null
		TYPE_PACKED_VECTOR3_ARRAY : # 36
			return null
		TYPE_PACKED_COLOR_ARRAY : # 37
			return null
		TYPE_MAX : # 38
			return null
	return null
