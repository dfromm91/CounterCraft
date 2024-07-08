extends Node
@export var note_scene : PackedScene
@export var button_scene : PackedScene
var staff_size: int
var snapPoints=[115,106,98,89,81,73,65,57,48,39,31]
var xcoord=170
var note_cursor_image = preload("res://notecursor.png")
var turn =0
var leapCount=0

var harmony_to_ycoord_map={
	"b3":189,
	"a3":197,
	"g3":206,
	"f3":215,
	"e3":224,
	"d3":230,
	"c3":238,
	"b2":246,
	"a2":255,
	"g2":264,
	"f2":272
}
var notecursor
var message=""
# Called when the node enters the scene tree for the first time.
func _ready():
	notecursor=get_node('notecursor')
	staff_size=$staff.texture.get_width()
	#Input.set_custom_mouse_cursor(note_cursor_image, Input.CURSOR_ARROW)
	Input.mouse_mode=Input.MOUSE_MODE_HIDDEN
	display_cantus()

# Called every frame. 'delta' is the elapsed time since the previous frame.
@warning_ignore("unused_parameter")
func _process(delta):
	notecursor.position=get_viewport().get_mouse_position()
	notecursor.position.x+=5
	notecursor.position.y+=5
func _input(event):
	if !Globals.playing and !Globals.over:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				if event.position.x < staff_size:
					var note = note_scene.instantiate()
					var closest_distance = 1e6  # A large number
					var closest_y_position = 0
					if get_viewport().get_mouse_position().y<200:
						for i in range(snapPoints.size()):
							var distance = abs(snapPoints[i] - event.position.y-5)
							if distance < closest_distance:
								closest_distance = distance
								closest_y_position = snapPoints[i]
						note.position.y = closest_y_position
						Globals.noteArray.append(closest_y_position)
						Globals.minterval.append(snapPoints.find(closest_y_position)+12)
						
						
						note.position.x = xcoord
						xcoord=(xcoord+55)
						add_child(note)
						if check_legality(turn):
							Globals.play_notes([Globals.noteArray[turn]],[Globals.harmony[turn]])
						else:
							Globals.play_notes(Globals.noteArray,Globals.harmony)
							var x=get_node('x')
							x.position.x=xcoord-55
							x.position.y=closest_y_position
							x.visible=true
							Globals.over=true
							get_node('Label').text=message
							var button=button_scene.instantiate()
							button.position.x=500
							button.position.y=130
							add_child(button)
							button.text='try again?'
							xcoord=170
							turn=0
							leapCount=0	
						turn+=1	
						if turn==16:
							Globals.over=true
							var button=button_scene.instantiate()
							button.position.x=500
							button.position.y=130
							
							add_child(button)
							Globals.play_notes(Globals.noteArray,Globals.harmony)
							button.text='You did it! \n Another round?'	
							xcoord=170
							turn=0
							leapCount=0	
		if Input.is_key_pressed(KEY_P):
			print(Globals.minterval)
					
func check_legality(turn):
	var cf_note = Globals.hinterval[turn]
	var melody_note = Globals.minterval[turn]
	var last_melody_note
	var last_cf_note
	var last_last_melody_note
	var last_last_cf_note 
	var cf_step
	var melody_step
	var illegal_intervals=[1,3,6]
	var ActualInterval=melody_note-cf_note
	var interval = (melody_note-cf_note)%7
	
	if interval in illegal_intervals:
		message="illegal interval: "+str(interval+1)
		return false
	var notes_in_c_major = ["f", "g", "a", "b", "c", "d", "e"]
	var cf_note_name = notes_in_c_major[cf_note % 7]
	var melody_note_name = notes_in_c_major[melody_note % 7]

	if (cf_note_name == "f" and melody_note_name == "b") or (cf_note_name == "b" and melody_note_name == "f"):
		message="Tritone"
		return false
	if turn>0:
		last_melody_note=Globals.minterval[turn-1]
		last_cf_note=Globals.hinterval[turn-1]
		melody_step=melody_note-last_melody_note
		cf_step=cf_note-last_cf_note
		var parallel=false	
		if melody_step==0:			
			message='repeated note'
			return false
		if (melody_step<0 and cf_step<0) or (melody_step>0 and cf_step>0):
			parallel=true
		if parallel and interval in [4,0]:
			message='direct octave or fifth'
			return false
		if abs(melody_step)>5:
			message='too big of a leap'
			return false
		if abs(melody_step)>1:
			leapCount+=1
		else:
			leapCount=0
		if leapCount>3:
			message='Too many leaps'
			return false
		if (melody_step<-1 and cf_step<-1) or (melody_step>1 and cf_step>1):
			message='simultaneous leap in same direction'
			return false
		if (melody_step>1 and cf_step<-1) or (melody_step<-1 and cf_step>1):
			if abs(melody_step)==2 and abs(cf_step)==2:
				message='legal opposite leap'
				return true
			elif (abs(melody_step)==3 and abs(cf_step)==2) or (abs(melody_step)==2 and abs(cf_step)==3):
				message='legal opposite leap'
				return true
			else:
				message='Illegal simultaneous leap'
				return false
	return true
	
func display_cantus():

	var xcord=170
	for h in Globals.harmony:
		var n=note_scene.instantiate()
		var ycord=harmony_to_ycoord_map[h]
		n.position.y=ycord
		n.position.x=xcord
		xcord+=55
		add_child(n)
