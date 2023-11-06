extends Node2D
# This script is the general event handler of the game.
# It coordinates information and event triggers between different scenes and UI elements. 
# Signal-related functions typically start with an underscore (_), while functions that are simply called do not

#UI elements
onready var notepad = get_parent().get_node("UI/To do")
onready var moxie = get_parent().get_node("Moxie")
onready var left = get_parent().get_node("UI/Left") # left arrow
onready var right = get_parent().get_node("UI/Right") # right arrow
onready var inventory = get_parent().get_node("UI/Inventory")
onready var inventoryUI = get_parent().get_node("UI/Inventory UI")
onready var deselect = get_parent().get_node("UI/Inventory control")
onready var energy = get_parent().get_node("UI/Energy bar")
onready var dialogue = get_parent().get_node("UI/Dialogue Box/RichTextLabel")
onready var movementHandle = get_parent().get_node("UI/Movement Handler") # not a UI element, just the node that handles the left/right movement between rooms

onready var cutsceneHandler = get_parent().get_node("Cutscenes") # node that has all the cutscenes under it
onready var pathHandler = get_parent().get_node("Moxie/Path2D/PathFollow2D") # node that controls the room's path
onready var sfxHandler = get_parent().get_node("UI/SFXHandler")

#rooms
onready var bedroom = get_parent().get_node("Bedroom")
onready var bathroom = get_parent().get_node("Bathroom")
onready var kitchen = get_parent().get_node("Kitchen")
onready var laundryBasket = get_parent().get_node("Laundry basket")
onready var laundryArea = get_parent().get_node("Laundry area")
onready var laundryNotepad = get_parent().get_node("Laundry - Notepad")
onready var fridge = get_parent().get_node("Fridge")
onready var desk =  get_parent().get_node("Desk")
onready var insideCabinet =  get_parent().get_node("Inside cabinet")
onready var livingRoom =  get_parent().get_node("Living room")
onready var plantNotepad = get_parent().get_node("Living room - Notepad")
onready var hallway =  get_parent().get_node("Hallway")
onready var balcony  =  get_parent().get_node("Balcony")
onready var neighborsRoom =  get_parent().get_node("Neighbor's room")
onready var neighborsBalcony  =  get_parent().get_node("Neighbor's balcony")

#functioning stuff
onready var quests = notepad.get_node("Quests") # the specific quest list
onready var groceries = false #if groceries were put away
onready var newQuests = false # if the 2nd round of quests have been given
onready var lockedNotepad #if ur locked from certain areas bc u havent gotten the notebook yet
onready var labNotes = 0 # how many lab notes have been collected
onready var clothes = 0 # how many pieces of clothing have been collected in the bedroom
onready var bathroomClean = 0 # how much of the bathroom has been cleaned
onready var cleaningMaterials = 0 # how many times the cleaning materials have been successfully used
onready var canFrontDoor = false # whether or not Moxie has a reason to go to leave their apartment, and so go to the hallway
onready var foundBanana = false # whether or not Moxie has spotted Banana in the balcony
onready var plungerUsed = false # whether or not the plunger was used to travel between balconies
onready var takenBanana = false

#items in the rooms that need access to the event handler
export(Array, NodePath) onready var eventItems

# Called when the node enters the scene tree for the first time.
func _ready():
	notepad.hide()
	for item in eventItems: # passes a reference to the handler to all listed items, so that they can connect a certain signal to a function in this script
		get_node(item).passEvent(self)
	lockedNotepad = true # ensures that certain areas are locked before the player retrieves the notebook
	right.hide()
	left.hide()

# ----------------- Quest progression-related events ----------------- 
func _get_notebook(): # when To Do list is retrieved for the first time
	notepad.show()
	right.show()
	_return_laundry()
	quests.add("Eat")
	movementHandle.enableMovement()
	lockedNotepad = false
	bedroom.get_node("Laundry basket").finished()
	dialogue.text = "Found it! Guess I have unfinished business to deal with."
	dialogue.playText()

func _groceries_put_away(): # when the groceries are put away
	kitchen.get_node("Granola bar").show()
	groceries = true
	laundryArea.get_node("Laundry door").flavorText = "I think I'm still missing something..."
	inventory.add_item("Oil", load("res://.import/Oil.png-29f84e969418d0f4084115c5ce859866.stex"))
	inventory.add_item("Cleaning materials", load("res://.import/cleaning materials.png-9e1abb8a1d84afe3085c773f150c7347.stex"))
	inventory.add_item("Laundry detergent",load("res://.import/soap.png-93c3e5ae993592d84ef303c214def992.stex"))

func _eaten(): # completing first "Eat" quest
	quests.finishQuest("Eat")

func _start_lab(): # trying the lab the first time, adds the new quests -> no longer in effect, moved to Cutscene 2
	#if !quests.hasQuest("Eat") and !quests.hasQuest("Do laundry"):
		#_start_cutscene_2b()
	pass

func _finish_lab():
	if quests.size() == 1 and quests.get_quest(0) == "Do Lab (Notes: 4/4)":
		_start_cutscene_3()
		quests.finishQuest("Do Lab (Notes: 4/4)")
		dialogue.text = "Congratulations!"
		dialogue.playText()
	else:
		dialogue.text = "Too tired. Gotta relax first. Need carbohydrates. Can't I do something less stressful first? Please and thank you."
		dialogue.playText()

func _add_quest(questName): # adding a quest to the quest list
	quests.add(questName)

func _remove_quest(questName): # removing a quest from the quest list
	quests.finishQuest(questName)
	if questName == "Do something relaxing":
		moxie.rect_position = Vector2(554.483, 451.976)
	elif questName == "Figure out what's making that noise & get rid of it":
		laundryArea.get_node("Noise").visible = false
		kitchen.get_node("Noise").visible = false
		livingRoom.get_node("Noise").visible = false
		hallway.get_node("Noise").visible = false
		neighborsRoom.get_node("Noise").visible = false
	
func _add_lab_note(): # when a new lab note is retrieved
	labNotes = labNotes + 1
	print("Lab notes: " + str(labNotes))
	quests.addLabNote()

func get_lab_notes(): # returns how many lab notes the player has found
	return labNotes

func _add_clothes(): # adds to the number of pieces of clothing that have been collected
	clothes = clothes + 1

func get_clothes(): # returns the number of pieces of clothing that have been collected
	return clothes

func _clean(toolUsed): # adds to the number of items that have been cleaned, and to the number of times the cleaning materials have been used
	bathroomClean = bathroomClean + 1
	print("Cleaning " + str(bathroomClean))
	if toolUsed == "Cleaning materials":
		cleaningMaterials += 1
	if cleaningMaterials == 3: # if the cleaning materials have cleaned 3 objects (sink, mirror, and floor), remove it 
		inventory.remove_item_name("Cleaning materials") 
	if bathroomClean == 5: # if it's done, finish the quest
		quests.finishQuest("Clean bathroom and take out trash")

func getClean(): # returns the number of objects that have been cleaned
	return bathroomClean

func _foundBanana(): # keeps track that Banana has been spotted on the balcony
	foundBanana = true

func finished2ndRound():
	if !desk.get_node("Laptop").gaveTired():
		desk.get_node("Laptop").tired()

func _self_care():
	livingRoom.get_node("Yoga mat").flavorText = "How do you do yoga again? I think that yoga guy posted a new video on some poses earlier."
	livingRoom.get_node("Yoga mat").canYoga()
	if !desk.get_node("Laptop").gaveTired():
		quests.add("Eat a snack")
		quests.add("Do something relaxing")
		kitchen.get_node("Granola bar").canEatGranola()

func _balcony_outer_lock():
	livingRoom.get_node("Balcony door").outerLock()
	neighborsBalcony.hide()
	balcony.show()
	movementHandle.setRoom(3)
	movementHandle.disableMovement()
	movementHandle.getRoomPosition("Balcony")
	if !quests.hasQuest("Clean bathroom and take out trash"):
		inventory.remove_item_name("Plunger")
	plungerUsed = true
		
func getPlungered():
	return plungerUsed

func bananaTaken(): # when banana is taken from the balcony, hides her from neighbor's balcony
	if !takenBanana:
		neighborsBalcony.get_node("Nana from afar").queue_free()
		livingRoom.get_node("Banana").queue_free()
		takenBanana = true
	

# ----------------- Cutscene initiators ----------------- 
func _start_cutscene_1():
	inventory.unselect_all()
	cutsceneHandler.get_node("1").show()
	cutsceneHandler.get_node("1/Scene control").start()
	dialogue.text = "Laundry time! Let's see if I can practice breaking things down."

func _start_cutscene_2():
	if !quests.hasQuest("Eat") and !quests.hasQuest("Do laundry"):
		inventory.unselect_all()
		cutsceneHandler.get_node("2").show()
		cutsceneHandler.get_node("2/Scene control").start()
		# adding quests and shifting to next phase
		quests.add("Clean bathroom and take out trash")
		quests.add("Figure out what's making that noise & get rid of it")
		quests.add("Feed Banana")
		quests.add("Repot plants")
		quests.add("Do Lab (Notes: 0/4)")
		newQuests = true
		movementHandle.finishTutorial()
		movementHandle.check_arrows()
		get_parent().get_node("Desk/Laptop").start()
		bedroom.get_node("Terrarium").removeBanana()
		bedroom.get_node("Terrarium").flavorText = "OMG! Where did Banana go??"
		dialogue.text = "Alright, let's...try and get things done!"
	
func _start_cutscene_2b():
	inventory.unselect_all()
	cutsceneHandler.get_node("2b").show()
	cutsceneHandler.get_node("2b/Scene control").start()

func _start_cutscene_3():
	inventory.unselect_all()
	cutsceneHandler.get_node("3").show()
	cutsceneHandler.get_node("3/Scene control").start()

# ----------------- Notebook puzzle events ----------------- 
func getGroceries():
	return groceries

func _enter_notebook_laundry(): # trying to engage in the notebook puzzle for doing laundry
	if !quests.hasQuest("Do laundry"):
		return "Let's just let the machine do its job."
	elif groceries: # if the groceries have been put away
		if clothes == 4:
			laundryArea.hide()
			laundryNotepad.show()
			zoom_in()
			notepad.force_open()
			notepad.get_node("Quests").hide()
			notepad.get_node("Title").text = "Words"
			var notepad_words = notepad.get_node("Words")
			notepad.get_node("Words").clear()
			notepad_words.show()
			notepad_words.add_item("Open")
			notepad_words.add_item("Close")
			notepad_words.add_item("Turn on")
			notepad_words.add_item("Put in")
			notepad_words.add_item("Look at")
			notepad.get_node("CollisionPolygon2D").disabled = true
			return "Alright, lets do this!"
		else:
			return "I still need to pick up all my clothes!"
	else: # if not, don't progress yet
		return "The groceries are still in the way."

func _laundry_finished(): # finishing notebook puzzle for laundry
	quests.finishQuest("Do laundry")
	inventory.remove_item_name("Dirty clothes")
	inventory.remove_item_name("Laundry detergent")
	laundryArea.get_node("Laundry door").flavorText = "Let's just let the machine do its job."

func _return_laundry_notepad(): # exiting laundry notebook puzzle
	zoom_out()
	laundryArea.show()
	laundryNotepad.hide()
	notepad._open_UI()
	notepad.get_node("Quests").show()
	notepad.get_node("Title").text = "To do (click to expand):"
	notepad.get_node("Words").hide()
	notepad.get_node("CollisionPolygon2D").disabled = false
	movementHandle.checkRoom()
	_start_cutscene_2()

func _enter_notebook_plants(): # trying to engage in the notebook puzzle for doing laundry
	if !quests.hasQuest("Repot plants"):
		return "Did that already"
	else: # if the groceries have been put away
		#if inventory.hasItem("Pot") and inventory.hasItem("Tabo with water") and inventory.hasItem("Shovel"):
		livingRoom.hide()
		plantNotepad.show()
		zoom_in()
		notepad.force_open()
		notepad.get_node("Quests").hide()
		notepad.get_node("Title").text = "Words"
		var notepad_words = notepad.get_node("Words")
		notepad.get_node("Words").clear()
		notepad_words.show()
		notepad_words.add_item("Look at")
		notepad_words.add_item("Clean")
		notepad_words.add_item("Pick up")
		notepad_words.add_item("Put down")
		notepad_words.add_item("Put in")
		notepad.get_node("CollisionPolygon2D").disabled = true
		return "Awww my babies are growing up so fast. Looks like they've outgrown their pots. Time for some big boy pants!"

func _plants_finished():
	#quests.finishQuest("Repot plants")
	livingRoom.get_node("Plants").interactable = false
	livingRoom.get_node("Plants").retrievable = true
	livingRoom.get_node("Yoga mat").interactable = true
	livingRoom.get_node("Plants").flavorText = "Time to bring these outside for some sunlight!"
	livingRoom.get_node("Plants/Hitbox/Sprite").set_texture(load("res://.import/potted plant (repotted).png-3dc208dea4408a6b19d704a770115b80.stex"))
	inventory.remove_item_name("Pot")
	inventory.remove_item_name("Shovel")
	inventory.remove_item_name("Tabo with water")
	notepad.get_node("CollisionPolygon2D").disabled = false

func _return_plant_notepad(): # exiting laundry notebook puzzle
	zoom_out()
	livingRoom.show()
	plantNotepad.hide()
	notepad._open_UI()
	notepad.get_node("Quests").show()
	notepad.get_node("Title").text = "To do (click to expand):"
	notepad.get_node("Words").hide()
	notepad.get_node("CollisionPolygon2D").disabled = false
	movementHandle.checkRoom()

# -----------------  Movement-related events (traversing between rooms, locking/unlocking, etc) ----------------- 
func _bathroom_enter(): # entering bathroom
	if !lockedNotepad && newQuests: 
		bedroom.hide()
		bathroom.show()
		movementHandle.disableMovement()
		inventory.unselect_all()
		movementHandle.getRoomPosition("Bathroom")
		sfxHandler.play("Move")
	else:
		dialogue.text = "Nah, I don't really need to go yet."
		dialogue.playText()

func _bathroom_exit(): # exiting bathroom
	bathroom.hide()
	bedroom.show()
	movementHandle.enableMovement()
	inventory.unselect_all()
	movementHandle.getRoomPosition("Bedroom")
	sfxHandler.play("Move")

func _balcony_enter(): # entering balcony
	movementHandle.disableMovement()
	balcony.show()
	livingRoom.hide()
	inventory.unselect_all()
	movementHandle.getRoomPosition("Balcony")
	sfxHandler.play("Move")

func _balcony_exit(): # exiting balcony
	movementHandle.enableMovement()
	balcony.hide()
	livingRoom.show()
	inventory.unselect_all()
	movementHandle.getRoomPosition("Living Room")
	sfxHandler.play("Move")

func _living_to_hallway(): # moving from living room to hallway, if there's a reason to
	if ((inventory.hasItem("Trash") != -1) || foundBanana): # either Moxie has to take out the trash or has to look for Banana
		canFrontDoor = true # leaving the apartment is now permanently enabled
	
	if canFrontDoor:
		movementHandle.disableMovement()
		livingRoom.hide()
		hallway.show()
		canFrontDoor = true
		if quests.hasQuest("Figure out what's making that noise & get rid of it"):
			dialogue.text = "What is that noise? Sounds like my neighbor's trying to break down their walls."
		dialogue.playText()
		inventory.unselect_all()
		movementHandle.getRoomPosition("Hallway")
		sfxHandler.play("Move")
	else: 
		dialogue.text = "You know, my philosophy has always been, 'If there's no reason to leave my apartment, why leave?'"
		dialogue.playText()
	
func _hallway_to_living(): # moving from hallway to moxie's living room
	movementHandle.enableMovement()
	hallway.hide()
	livingRoom.show()
	inventory.unselect_all()
	movementHandle.getRoomPosition("Living room")
	sfxHandler.play("Move")

func _hallway_to_neighbor(): # moving from hallway to neighbor's living room
	movementHandle.disableMovement()
	hallway.hide()
	neighborsRoom.show()
	inventory.unselect_all()
	movementHandle.getRoomPosition("Neighbor's room")
	sfxHandler.play("Move")

func _neighbor_to_hallway(): # moving from neighbor's living room to the hallway
	hallway.show()
	neighborsRoom.hide()
	movementHandle.checkRoom()
	inventory.unselect_all()
	movementHandle.getRoomPosition("Hallway")
	sfxHandler.play("Move")

func _neighbor_to_balcony(): # moving from neighbor's living room to their balcony
	movementHandle.disableMovement()
	neighborsRoom.hide()
	neighborsBalcony.show()
	inventory.unselect_all()
	movementHandle.getRoomPosition("Neighbor's balcony")
	sfxHandler.play("Move")

func _balcony_to_neighbor(): # moving from neighbor's balcony to their living room
	neighborsRoom.show()
	neighborsBalcony.hide()
	movementHandle.checkRoom()
	inventory.unselect_all()
	movementHandle.getRoomPosition("Neighbor's room")
	sfxHandler.play("Move")

# -----------------  Zooming in and out of specific views ----------------- 
func zoom_in(): # for close up perspectives without some UI
	moxie.hide()
	inventoryUI.hide()
	left.hide()
	right.hide()
	deselect.hide()
	movementHandle.disableMovement()
	inventory.unselect_all()

func zoom_out(): # for returning from close up perspectives
	sfxHandler.play("Move")
	moxie.show()
	inventoryUI.show()
	if !lockedNotepad:
		#get_parent().get_node("UI/Movement Handler").check_arrows() # show arrows depending on situation
		movementHandle.enableMovement()
	deselect.show()
	#movementHandle.checkRoom()
	inventory.unselect_all()

func _laundry_basket(): # looking at the laundry basket view
	bedroom.hide()
	laundryBasket.show()
	zoom_in()

func _return_laundry(): # returning from laundry basket view
	laundryBasket.hide()
	bedroom.show()
	zoom_out()

func _open_fridge(): # looking into the fridge
	if quests.hasQuest("Eat"):
		kitchen.hide()
		fridge.show()
		zoom_in()
		notepad.hide()
		dialogue.text = "Do I want a snack, or do I want to throw something together to make a sandwich? It'd take more work but it'd be yummier!"
		dialogue.playText()
	else:
		dialogue.text = "Not quite dinnertime yet!"
		dialogue.playText()

func _return_fridge(): # returning from fridge view
	fridge.hide()
	kitchen.show()
	zoom_out()
	notepad.show()
	_start_cutscene_2()

func _open_cabinet(): # looking inside kitchen cabinet
	zoom_in()
	inventoryUI.show()
	deselect.show()
	kitchen.hide()
	insideCabinet.show()

func getCabinet(item):
	kitchen.get_node("Cabinet/Hitbox/"+item).visible = false

func _close_cabinet(): # leaving kitchen cabinet
	zoom_out()
	kitchen.show()
	insideCabinet.hide()

func _in_desk(): # looking at desk
	if !lockedNotepad: # only if notepad has been retrieved
		zoom_in()
		inventoryUI.show()
		deselect.show()
		desk.show()
		bedroom.hide()

func _out_desk(): # leaving desk
	zoom_out()
	desk.hide()
	bedroom.show()

# -----------------  To be removed ----------------- 
#func connect_stools(): # connecting the two instances of the stool so that one disappears when the other is retrieved
#	get_parent().get_node("Laundry area/Stool").giveStool(get_parent().get_node("Kitchen/Stool"))
#	get_parent().get_node("Kitchen/Stool").giveStool(get_parent().get_node("Laundry area/Stool"))

# -----------------  Other ----------------- 
func give_energy_bar(): # returns energy bar node
	return energy

