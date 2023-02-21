@tool
extends Resource
class_name PostProcessingEffect

@export var id : String = ""
@export var materials : Array[Material] = []
@export var layer : int
@export var showInGame : bool = true
@export var showInEditor : bool = true
