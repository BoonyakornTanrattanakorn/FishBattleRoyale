extends Label
class_name ToxicZoneUI

## UI element to display toxic zone wave information

var current_wave := 0
var safe_percentage := 100.0
var warning_active := false

func _ready() -> void:
	update_display()


func set_wave(wave: int) -> void:
	current_wave = wave
	update_display()
	
	# Flash warning when new wave hits
	if wave > 0:
		flash_warning()


func set_safe_percentage(percentage: float) -> void:
	safe_percentage = percentage
	update_display()


func update_display() -> void:
	if current_wave == 0:
		text = "🌊 Zone: Safe"
		modulate = Color.WHITE
	else:
		text = "🌊 Wave %d | Safe: %.0f%%" % [current_wave, safe_percentage]
		
		# Color code based on danger
		if safe_percentage > 60:
			modulate = Color.WHITE
		elif safe_percentage > 30:
			modulate = Color.ORANGE
		else:
			modulate = Color.RED


func flash_warning() -> void:
	if warning_active:
		return
	
	warning_active = true
	var original_scale := scale
	
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC)
	
	tween.tween_property(self, "scale", original_scale * 1.3, 0.2)
	tween.tween_property(self, "scale", original_scale, 0.5)
	
	await tween.finished
	warning_active = false


func show_countdown(seconds: float) -> void:
	# Show countdown to next wave
	text = "⚠️ Next Wave: %.0fs" % seconds
	modulate = Color.YELLOW
