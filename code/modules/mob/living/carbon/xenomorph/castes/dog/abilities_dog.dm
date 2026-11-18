// ***************************************
// *********** Runner's Pounce
// ***************************************
#define DOG_POUNCE_RANGE 6 // in tiles
#define DOG_SAVAGE_DAMAGE_MINIMUM 15
#define DOG_SAVAGE_COOLDOWN 30 SECONDS

/datum/action/ability/activable/xeno/pounce/dog
	desc = "Leap at your target, tackling and disarming them. Alternate use toggles Savage off or on."
	action_icon_state = "pounce_savage_on"
	ability_cost = 10
	keybinding_signals = list(
		KEYBINDING_NORMAL = COMSIG_XENOABILITY_RUNNER_POUNCE,
		KEYBINDING_ALTERNATE = COMSIG_XENOABILITY_TOGGLE_SAVAGE,
	)
	pounce_range = DOG_POUNCE_RANGE
	/// Whether Savage is active or not.
	var/savage_activated = TRUE
	/// The amount of deciseconds that confusion will last and the potency of the blurriness.
	var/savage_debuff_amount = 0
	/// Savage's cooldown.
	COOLDOWN_DECLARE(savage_cooldown)

/datum/action/ability/activable/xeno/pounce/dog/give_action(mob/living/L)
	. = ..()
	var/mutable_appearance/savage_maptext = mutable_appearance(icon = null, icon_state = null, layer = ACTION_LAYER_MAPTEXT)
	savage_maptext.pixel_x = 12
	savage_maptext.pixel_y = -5
	visual_references[VREF_MUTABLE_SAVAGE_COOLDOWN] = savage_maptext

/datum/action/ability/activable/xeno/pounce/dog/alternate_action_activate()
	savage_activated = !savage_activated
	owner.balloon_alert(owner, "Savage [savage_activated ? "activated" : "deactivated"]")
	action_icon_state = "pounce_savage_[savage_activated? "on" : "off"]"
	update_button_icon()

/datum/action/ability/activable/xeno/pounce/dog/trigger_pounce_effect(mob/living/living_target)
	. = ..()
	if(!savage_activated)
		return
	if(!COOLDOWN_FINISHED(src, savage_cooldown))
		owner.balloon_alert(owner, "Savage on cooldown ([COOLDOWN_TIMELEFT(src, savage_cooldown) * 0.1]s)")
		return
	var/savage_damage = max(DOG_SAVAGE_DAMAGE_MINIMUM, xeno_owner.plasma_stored * 0.15)
	var/savage_cost = savage_damage * 2
	if(xeno_owner.plasma_stored < savage_cost)
		owner.balloon_alert(owner, "Not enough plasma to Savage ([savage_cost])")
		return
	living_target.attack_alien_harm(xeno_owner, savage_damage)
	if(savage_debuff_amount)
		living_target.adjust_blurriness(savage_debuff_amount * 0.2) // Blurriness goes away at a decent speed when nothing else keeps adding to it.
		living_target.AdjustConfused(savage_debuff_amount)
	xeno_owner.use_plasma(savage_cost)
	COOLDOWN_START(src, savage_cooldown, DOG_SAVAGE_COOLDOWN)
	START_PROCESSING(SSprocessing, src)

/datum/action/ability/activable/xeno/pounce/dog/process()
	if(COOLDOWN_FINISHED(src, savage_cooldown))
		button.cut_overlay(visual_references[VREF_MUTABLE_SAVAGE_COOLDOWN])
		owner.balloon_alert(owner, "Savage ready")
		owner.playsound_local(owner, 'sound/effects/alien/newlarva.ogg', 25, 0, 1)
		STOP_PROCESSING(SSprocessing, src)
		return
	button.cut_overlay(visual_references[VREF_MUTABLE_SAVAGE_COOLDOWN])
	var/mutable_appearance/cooldown = visual_references[VREF_MUTABLE_SAVAGE_COOLDOWN]
	cooldown.maptext = MAPTEXT("[round(COOLDOWN_TIMELEFT(src, savage_cooldown) * 0.1)]s")
	visual_references[VREF_MUTABLE_SAVAGE_COOLDOWN] = cooldown
	button.add_overlay(visual_references[VREF_MUTABLE_SAVAGE_COOLDOWN])

/datum/action/ability/activable/xeno/pounce/dog/clean_action()
	STOP_PROCESSING(SSprocessing, src)
	return ..()
