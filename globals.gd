extends Node
var noteArray=[]
var notes = []
var harmony = []
var hnote
var hinterval=[4]
var minterval=[]
var playing=false
var over=false
var readervis=false
var readerpos=172
var note_to_audio_node_map = {
	65: "c5",
	57: "d5",
	48: "e5",
	39: "f5",
	31: "g5",
	73: "b4",
	81: "a4",
	89: "g4",
	98: "f4",
	106: "e4",
	115: "d4"
}

# A mapping function to convert note numbers to their string representations
func note_number_to_string(note_number):
	var note_names = ["f2","g2","a2","b2","c3","d3","e3","f3","g3","a3","b3"]
	return note_names[note_number - 1]  # Adjust for 0-indexing

func _ready():
	generate_cantus_firmus()
	
func generate_cantus_firmus():
	var notes = ["f2", "g2", "a2", "b2", "c3", "d3", "e3", "f3", "g3", "a3", "b3"]
	var cf_array = ["c3"]
	var last_note_index = 4  # Index of c3 in the updated array
	var direction = 0  # -1 for downward, 1 for upward
	var consecutive_steps = 0
	var leap_occurred = false
	var attempts = 0

	while cf_array.size() < 15:
		if attempts > 100:  # Prevent infinite loop
			print("Too many attempts, breaking loop.")
			break

		var next_index = last_note_index
		var possible_steps = [1, -1, 2, -2]  # Possible movements: step up, step down, leap up, leap down

		if direction != 0 and consecutive_steps >= 3:
			direction *= -1
			consecutive_steps = 0

		var selected_step = possible_steps[randi() % possible_steps.size()]
		next_index += selected_step
		if next_index >= 0 and next_index < notes.size():
			if abs(selected_step) > 1:
				if leap_occurred:
					attempts += 1
					continue
				leap_occurred = true
				consecutive_steps = 0

			cf_array.append(notes[next_index])
			hinterval.append(next_index)
			last_note_index = next_index
			direction =  1 if selected_step > 0 else -1
			consecutive_steps += 1
		else:
			attempts += 1

	cf_array.append("c3")
	hinterval.append(4)
	harmony= cf_array
	print (hinterval)
	
signal notes_finished

var players_finished = 0

func play_notes(note_array, harmony_array):
	playing=true
	
	if note_array.size()>1:
		readervis=true
	for i in range(note_array.size()):
		# Ensure the index is within the bounds of both arrays
		if i >= harmony_array.size():
			break

		var note = note_array[i]
		var node_name = note_to_audio_node_map[note]
		var harmony_note = harmony_array[i]
		var audio_player = get_node("/root/main/"+node_name)
		var harmony_player = get_node("/root/main/"+harmony_array[i])

		# Check if nodes are valid
		if not audio_player or not harmony_player:
			print("One of the players is not a valid node.")
			continue

		# Reset the counter for each pair of notes
		players_finished = 0

		# Connect the finished signals and play the notes
		audio_player.finished.connect(_on_player_finished)
		harmony_player.finished.connect(_on_player_finished)
		audio_player.play()
		harmony_player.play()
		
		if harmony_note in ["b2", "g2", "f2"]:
			var half_duration = harmony_player.stream.get_length() / 2.0
			var timer = Timer.new()  # Create a new Timer instance
			timer.set_wait_time(half_duration)
			timer.one_shot = true
			Globals.hnote=harmony_player
			timer.timeout.connect(_on_half_duration_timeout)
			add_child(timer)
			timer.start()


		# Wait for the notes to finish
		while players_finished < 2:
			await get_tree().process_frame
		readerpos+=55
		# Disconnect signals to avoid duplicate connections in the next iteration
		audio_player.finished.disconnect(_on_player_finished)
		harmony_player.finished.disconnect(_on_player_finished)
		
	readervis=false
	readerpos=172
	playing=false
func _on_half_duration_timeout():
		Globals.hnote.stop()  # Stop the player after half its duration
		players_finished += 1  # Increment the counter as this counts as finishing the playback	

func _on_player_finished():
	players_finished += 1
	if players_finished >= 2:
		# This condition is to ensure that even if for some reason the signal is emitted more than once per player, it does not affect the flow.
		emit_signal("notes_finished")
