extends Node

# Random fish name generator for players

const ADJECTIVES := [
	"Speedy", "Angry", "Happy", "Silly", "Sparkly", "Grumpy", "Jumpy", "Sleepy",
	"Bouncy", "Dizzy", "Fancy", "Goofy", "Lazy", "Mighty", "Shiny", "Sneaky",
	"Crazy", "Brave", "Clumsy", "Lucky", "Slippery", "Wacky", "Zippy", "Bubbly"
]

const FISH_TYPES := [
	"Goldfish", "Tuna", "Salmon", "Shark", "Clownfish", "Pufferfish", "Swordfish",
	"Catfish", "Angelfish", "Barracuda", "Jellyfish", "Octopus", "Seahorse", "Starfish",
	"Dolphin", "Whale", "Eel", "Manta Ray", "Squid", "Crab", "Lobster", "Shrimp"
]

var used_names := []

func generate_random_name() -> String:
	var attempts := 0
	var max_attempts := 100
	
	while attempts < max_attempts:
		var adjective = ADJECTIVES[randi() % ADJECTIVES.size()]
		var fish_type = FISH_TYPES[randi() % FISH_TYPES.size()]
		var name := "%s %s" % [adjective, fish_type]
		
		if name not in used_names:
			used_names.append(name)
			return name
		
		attempts += 1
	
	# Fallback: add a number if all combinations are exhausted
	var fallback_name := "Fish %d" % (used_names.size() + 1)
	used_names.append(fallback_name)
	return fallback_name

func reserve_name(name: String) -> void:
	if name not in used_names:
		used_names.append(name)

func release_name(name: String) -> void:
	used_names.erase(name)

func is_name_available(name: String) -> bool:
	return name not in used_names

func clear_all_names() -> void:
	used_names.clear()
