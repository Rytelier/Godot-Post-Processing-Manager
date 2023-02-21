@tool
extends EditorPlugin


var managerCurrent : PostProcessingManager
var editor3DViewport : SubViewportContainer
var editor2DViewport : SubViewportContainer

var canvasLayers3D : Array[CanvasLayer] = []
var colorRects3D : Array[ColorRect] = []

var canvasLayers2D : Array[CanvasLayer] = []
var colorRects2D : Array[ColorRect] = []

var effectsToggleButton3D : Button
var effectsToggleButton2D : Button


func _enter_tree():
	add_custom_type("PostProcessingEffect", "Resource", preload("res://addons/PostProcessing/PostProcessingEffect.gd"), preload("res://addons/PostProcessing/Resources/Effect.svg"))
	add_custom_type("PostProcessingManager", "Node", preload("res://addons/PostProcessing/PostProcessingManager.gd"), preload("res://addons/PostProcessing/Resources/Manager.svg"))
	
	Init()
	FindManagerInScene()
	UpdateEffects()
	#editor2DViewport.item_rect_changed.connect(UpdateRects2D.bind())
	
	effectsToggleButton3D = preload("res://addons/PostProcessing/Resources/EffectEditorToggle.tscn").instantiate()
	effectsToggleButton3D.pressed.connect(ToggleEditorEffectsButton.bind())
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, effectsToggleButton3D)
	effectsToggleButton3D.reparent(effectsToggleButton3D.get_parent().get_parent().get_parent().get_children()[0]) #Move to main toolbar section
	effectsToggleButton3D.button_pressed = true
	
	effectsToggleButton2D = preload("res://addons/PostProcessing/Resources/EffectEditorToggle.tscn").instantiate()
	effectsToggleButton2D.pressed.connect(ToggleEditorEffectsButton.bind(true))
	add_control_to_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, effectsToggleButton2D)
	effectsToggleButton2D.reparent(effectsToggleButton2D.get_parent().get_parent().get_parent().get_children()[0]) #Move to main toolbar section
	effectsToggleButton2D.button_pressed = true
	
	scene_changed.connect(OnSceneChanged.bind())

	pass


func _exit_tree():
	remove_custom_type("PostProcessingEffect")
	remove_custom_type("PostProcessingManager")
	
	effectsToggleButton3D.queue_free()
	effectsToggleButton2D.queue_free()
	
	Clear()
	
	pass

func Init():
	Clear()
	
	editor3DViewport = null
	editor2DViewport = null
	FindEditorViewports()

func Clear():
	for node in canvasLayers3D:
		node.queue_free()
	for node in colorRects3D:
		node.queue_free()
	
	canvasLayers3D.clear()
	colorRects3D.clear()
	
	for node in canvasLayers2D:
		node.queue_free()
	for node in colorRects2D:
		node.queue_free()
	
	canvasLayers2D.clear()
	colorRects2D.clear()

#
#
# Update
#
#

func UpdateEffects():
	Clear()
	
	if !managerCurrent.showInEditor: return
	if !is_instance_valid(editor3DViewport): return
	
	#print("[PostProcessing] Adding post processing effects in editor")
	for i in range(managerCurrent.effects.size()):
		managerCurrent.AddPostProcesingLayer(i, editor3DViewport.get_children()[0], canvasLayers3D, colorRects3D, true)
		managerCurrent.AddPostProcesingLayer(i, editor2DViewport.get_children()[0], canvasLayers2D, colorRects2D, true)
	
	#UpdateRects2D()

func UpdateRects2D():
	if !is_instance_valid(editor2DViewport): return
	if colorRects2D == null: return

	for i in range(colorRects2D.size()):
		if is_instance_valid(colorRects2D[i]):
			var rect = colorRects2D[i]
			#IMPLEMENT proper 2D rect covering the screen idk how to do this

#
#
# Interface
#
#

func ToggleEditorEffectsButton(button2D : bool = false):
	if !is_instance_valid(managerCurrent): FindManagerInScene()

	if !button2D:
		if effectsToggleButton3D.button_pressed:
			if !is_instance_valid(managerCurrent): return
			UpdateEffects()
		else:
			Clear();
		effectsToggleButton2D.button_pressed = effectsToggleButton3D.button_pressed
	else:
		if effectsToggleButton2D.button_pressed:
			if !is_instance_valid(managerCurrent): return
			UpdateEffects()
		else:
			Clear();
			
		effectsToggleButton3D.button_pressed = effectsToggleButton2D.button_pressed

func OnSceneChanged(x):
	FindManagerInScene()
	if !is_instance_valid(managerCurrent):
		Clear()
		return

	ToggleEditorEffectsButton();

#
#
# Find
#
#

func FindManagerInScene():
	if get_editor_interface().get_edited_scene_root() == null:
		managerCurrent = null
		return
	
	# Find by possible name variants
	managerCurrent = get_editor_interface().get_edited_scene_root().find_child("PostProcessingManager", true)
	if managerCurrent == null:
		managerCurrent = get_editor_interface().get_edited_scene_root().find_child("PostProcessingManager".to_snake_case(), true)
	if managerCurrent == null:
		managerCurrent = get_editor_interface().get_edited_scene_root().find_child("PostProcessingManager".to_camel_case(), true)

func FindByClass(node: Node, className : String, result : Array) -> void:
	if node.is_class(className) :
		result.push_back(node)
	for child in node.get_children():
		FindByClass(child, className, result)

func FindEditorViewports():
	var allViewports : Array[SubViewportContainer] = []
	FindByClass(get_editor_interface().get_base_control(), "SubViewportContainer", allViewports)
	
	# Find 3D view viewport
	for viewport in allViewports:
		if viewport.get_parent().get_class() == "Node3DEditorViewport":
			if viewport.get_children()[0].get_children()[0] is Camera3D:
				editor3DViewport = viewport
				break
	
	# Find 2D view viewport
	for viewport in allViewports:
		if viewport.get_parent().get_class() == "Control":
			if viewport.get_parent().get_children()[1].get_class() == "CanvasItemEditorViewport":
				editor2DViewport = viewport
				break
