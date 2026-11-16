class_name VillageEvent
extends RefCounted
## Base of the small village events (design/game-brief.md, Features item 5; story 005).
## An event is a small state machine owned and stepped by the [EventDirector]. It
## holds the villagers it uses by setting [member Villager.lock] to itself through
## [method hold], and every way it ends goes through [method finish] or
## [method cut_short], which both release every held villager back to its routine
## ([method VillagerRoutines.next_activity]). A villager is never left locked.
##
## Subclasses override [method start], [method update], and optionally
## [method _wind_down] (what happens when the day ends under the event) and
## [method _cleanup] (free sprites).

## True once the event has ended; the director then drops it.
var done: bool = false
## Seconds since the current phase began.
var phase_time: float = 0.0

var _director: EventDirector
var _held: Array[Villager] = []


func _init(director: EventDirector) -> void:
	_director = director


## Starts the event. Returns false, holding nobody, when it cannot run now.
func start() -> bool:
	return false


## Advances the event by [param _delta] seconds. Called by the director every physics
## step until [member done].
func update(_delta: float) -> void:
	pass


## The day ended under the event (dusk for a daytime event, dawn for the lantern
## round): every held villager is let go at once, then the event winds down (by
## default it ends at once).
func cut_short() -> void:
	if done:
		return
	release_all()
	_wind_down()


## Ends the event: releases every villager it holds and removes its sprites. Safe to
## call more than once.
func finish() -> void:
	if done:
		return
	done = true
	release_all()
	_cleanup()


## Locks [param villager] to this event; [method finish] will release it.
func hold(villager: Villager) -> void:
	villager.lock = self
	if not _held.has(villager):
		_held.append(villager)


## True while [param villager] is held by this event.
func holds(villager: Villager) -> bool:
	return is_instance_valid(villager) and villager.lock == self and _held.has(villager)


## Unlocks [param villager] (if this event holds it) and sends it back to its routine.
func release(villager: Villager) -> void:
	_held.erase(villager)
	if not is_instance_valid(villager) or villager.lock != self:
		return
	villager.lock = null
	_director.routines.next_activity(villager)


## Unlocks every villager this event holds.
func release_all() -> void:
	var held: Array[Villager] = _held.duplicate()
	for villager: Villager in held:
		release(villager)
	_held.clear()


## What happens after [method cut_short] has released everyone. Default: end at once.
func _wind_down() -> void:
	finish()


## Frees the event's own sprites. Called once, by [method finish].
func _cleanup() -> void:
	pass


## Checks [param to] against [param transitions] (from-phase -> Array of allowed
## to-phases) and resets [member phase_time]. Subclasses call it before changing phase.
func _check_transition(transitions: Dictionary, from: int, to: int) -> void:
	var allowed: Array = transitions.get(from, [])
	if not allowed.has(to):
		push_error("%s: no transition %d -> %d" % [get_script().get_global_name(), from, to])
	phase_time = 0.0
