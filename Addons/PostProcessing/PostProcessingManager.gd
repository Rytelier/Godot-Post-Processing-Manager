@tool
extends Node
class_name PostProcessingManager

@export var showInGame : bool = true
@export var showInEditor : bool = true

@export var effects : Array[PostProcessingEffect] = []

var canvasLayers : Array[CanvasLayer] = []
var colorRects : Array[ColorRect] = []

func _ready():
	if Engine.is_editor_hint():
		return
	if !showInGame:
		return
	
	AddEffects()

#
#

## Find effect by its ID
func GetEffect(id : String) -> PostProcessingEffect:
	for effect in effects:
		if effect.id == id:
			return effect
	
	return null

#
#

func AddEffects():
	for e in range(effects.size()):
		AddPostProcesingLayer(e, self, canvasLayers, colorRects)

func ClearEffects():
	if canvasLayers == null and colorRects == null: return
	
	for node in canvasLayers:
		node.queue_free()
	for node in colorRects:
		node.queue_free()
	
	canvasLayers.clear()
	colorRects.clear()

func AddPostProcesingLayer(effect : int, parent : Node, layers : Array[CanvasLayer], rects : Array[ColorRect], inEditor : bool = false):
	if !inEditor && !effects[effect].showInGame: return
	if  inEditor && !effects[effect].showInEditor: return

	if effects[effect].materials == null || effects[effect].materials.size() == 0: return

	for m in range(effects[effect].materials.size()):
		var layer : CanvasLayer = CanvasLayer.new()
		layers.append(layer)
		parent.add_child(layer)
		layer.layer = effects[effect].layer
		layer.follow_viewport_enabled = true

		var rect : ColorRect = ColorRect.new()
		rects.append(rect)
		layers[layers.size()-1].add_child(rect)

		rect.set_anchors_preset(Control.PRESET_FULL_RECT, true)
		rect.material = effects[effect].materials[m]
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

static func GetPostProcessingManager(node : Node) -> PostProcessingManager:
	return node.get_tree().root.find_child("PostProcessingManager", true)
