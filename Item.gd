extends StaticBody2D

# This is a general use script for all items in the game. Items with special uses extend this script, so any changes to this script will still affect everything.

#UI stuff
onready var dialogueBox # the dialogue box node, with a RichTextLabel inside
onready var inventory # the inventory
onready var quests # the actual Quests node
onready var path
onready var sfxHandler

#variables that are editable in the Inspector
export(bool) var retrievable # check if this item can be placed in the inventory
export(bool) var interactable # for environmental objects that are interactable but not retrievable
export(String) var flavorText # the flavor text that appears in the dialogue box when picked up
onready var control = get_parent().get_node("Dialogue control") # has a unique control in each room, this is the reference point for generating the flavor text of any interactions that don't have special effects

#other variables
onready var texture # the texture of the items's sprite, for passing to inventory

# some references
# https://docs.godotengine.org/en/stable/getting_started/scripting/gdscript/gdscript_exports.html
# https://padamthapa.com/blog/how-to-detect-click-inside-staticbody2d-in-godot/

func _ready():
	texture = get_node("Hitbox/Sprite").get_texture()
	
func passUI(inv, dia, que, pa, sfx): #passes the inventory and dialogue box from the parent scene to the item in the instanced scene
	inventory = inv
	dialogueBox = dia
	quests = que
	path = pa
	sfxHandler = sfx
	#print("Found " + dialogueBox.get_name())

func _input_event(viewport, event, shape_idx): # executes when clicked on
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.pressed:
			#print("Clicked on " + self.get_name() + " with selected " + str(inventory.is_anything_selected()))
			if inventory.is_anything_selected() and interactable: # if the player has an item selected and they use it on something interactable
				storeInt(inventory.get_selected_items()[0]) # sends the data for mouse tracking
				objInteraction(inventory.get_selected_items()[0])
			elif inventory.is_anything_selected() and retrievable: # use object on something retrievable
				storeInt(inventory.get_selected_items()[0]) # sends the data for mouse tracking
				objInteraction(inventory.get_selected_items()[0])
			elif !inventory.is_anything_selected() and retrievable: # if they click on something retrievable w/ empty hands
				storeClick("Picked up") # sends the data for mouse tracking
				pickup()
			elif interactable: #for environment things that arent retrievable, and hands are empty
				storeClick("Clicked on") # sends the data for mouse tracking
				mouseInteraction()
			if get_name() != "Return":
				path.move(position.x)
			#get_tree().set_input_as_handled()

func storeClick(method): # stores the mouse click data to data.save
	var save_data = File.new()
	var curTime = OS.get_time()
	var timestamp = "[" + str(curTime.hour) + ":" + str(curTime.minute) + ":" + str(curTime.second) + "]"
	if !save_data.file_exists("user://data.save"):
		save_data.open("user://data.save",File.WRITE)
		save_data.store_string("FILE START\n")
		save_data.store_string(": " + method + " " + get_name() + " " + timestamp)
		print("Created file")
	else:
		save_data.open("user://data.save",File.READ_WRITE)
		save_data.seek_end()
		save_data.store_string(": " + method + " " + get_name())
		#print("Writing to file")
	save_data.close()

func storeInt(selected): # specifically for using one item on another, stores mouse click data to data.save
	var save_data = File.new()
	var curTime = OS.get_time()
	var timestamp = "[" + str(curTime.hour) + ":" + str(curTime.minute) + ":" + str(curTime.second) + "]"
	if !save_data.file_exists("user://data.save"):
		save_data.open("user://data.save",File.WRITE)
		save_data.store_string("FILE START\n")
		save_data.store_string(": Used " + inventory.get_item_text(selected) + " -> " + get_name())
		print("Created file")
	else:
		save_data.open("user://data.save",File.READ_WRITE)
		save_data.seek_end()
		save_data.store_string(": Used " + inventory.get_item_text(selected) + " -> " + get_name())
		#print("Writing to file")
	save_data.close()
	

# override the following functions as needed when extending the script:
func mouseInteraction(): # just clicked on it with nothing
	dialogueBox.text = flavorText
	dialogueBox.playText()

func pickup(): # when it's picked up
	dialogueBox.text = flavorText
	dialogueBox.playText()
	inventory.add_item(self.get_name(), texture)
	queue_free()
	inventory.unselect_all()
	sfxHandler.play("Pickup")

func objInteraction(selected): # when an object is used on it
	print("Using " + inventory.get_item_text(selected) + " on " + self.name )
	var flavor = control.interaction(inventory.get_item_text(selected), self.get_name())
	if typeof(flavor) != 0: #checks if there's coded flavor text for this interaction
		dialogueBox.text = flavor
	else:
		dialogueBox.text = "I don't think that would help." #can replace this later!
	if inventory.get_name() == "Words":
		inventory.unselect_all()
	dialogueBox.playText()
