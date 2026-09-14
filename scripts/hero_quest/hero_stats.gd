class_name HeroStats
extends RefCounted

const ItemData = preload("res://scripts/hero_quest/item_data.gd")

signal stats_changed(stats_dict: Dictionary)
signal health_changed(current: int, maximum: int)

var hero_name: String = "Sir Christopher"
var hero_title: String = "Guardian of the Castle"

var base_attack: int = 1
var base_armor: int = 2
var base_max_hp: int = 8
var base_mind_points: int = 3

var current_attack: int = 1
var current_armor: int = 2
var current_max_hp: int = 8
var current_hp: int = 8
var current_mind_points: int = 3
var speed_bonus: float = 0.0

func _init() -> void:
	current_hp = base_max_hp
	current_max_hp = base_max_hp
	current_attack = base_attack
	current_armor = base_armor
	current_mind_points = base_mind_points

func recalculate(equipped_items: Array) -> void:
	var bonus_attack = 0
	var bonus_armor = 0
	var bonus_max_hp = 0
	var bonus_mind = 0
	var bonus_speed = 0.0

	for item in equipped_items:
		if item is ItemData:
			bonus_attack += item.attack_strength
			bonus_armor += item.armor
			bonus_max_hp += item.max_hp
			bonus_mind += item.mind_points
			bonus_speed += item.speed_bonus

	current_attack = base_attack + bonus_attack
	current_armor = base_armor + bonus_armor
	current_max_hp = base_max_hp + bonus_max_hp
	current_mind_points = base_mind_points + bonus_mind
	speed_bonus = bonus_speed

	current_hp = clampi(current_hp, 1, current_max_hp)

	stats_changed.emit(get_stats_dict())
	health_changed.emit(current_hp, current_max_hp)

func heal(amount: int) -> int:
	var old_hp = current_hp
	current_hp = mini(current_hp + amount, current_max_hp)
	var restored = current_hp - old_hp
	health_changed.emit(current_hp, current_max_hp)
	stats_changed.emit(get_stats_dict())
	return restored

func take_damage(amount: int) -> int:
	var actual_damage = maxi(0, amount)
	current_hp = maxi(0, current_hp - actual_damage)
	health_changed.emit(current_hp, current_max_hp)
	stats_changed.emit(get_stats_dict())
	return actual_damage

func get_stats_dict() -> Dictionary:
	return {
		"attack_strength": current_attack,
		"armor": current_armor,
		"current_hp": current_hp,
		"max_hp": current_max_hp,
		"mind_points": current_mind_points,
		"speed_bonus": speed_bonus,
		"base_attack": base_attack,
		"base_armor": base_armor
	}
