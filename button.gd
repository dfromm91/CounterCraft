extends Button


# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
var try=true
func _process(delta):
	if !Globals.playing and try:
		pressed.connect(reset)
		try=false

func reset():
	var main_scene_path = "res://main"  # Adjust the path as necessary
	Globals.noteArray=[]
	Globals.notes = []
	Globals.harmony = []
	Globals.hnote
	Globals.hinterval=[4]
	Globals.minterval=[]
	Globals.playing=false
	Globals.over=false
	get_tree().reload_current_scene()
	Globals.generate_cantus_firmus()
	get_parent().display_cantus()
