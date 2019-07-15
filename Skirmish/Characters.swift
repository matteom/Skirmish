//
//  Characters.swift
//  Skirmish
//
//  Created by Matteo Manferdini on 15/07/2019.
//  Copyright © 2019 Matteo Manferdini. All rights reserved.
//

import Foundation

// MARK: - Character
protocol Character {
	static var maxHealth: Int { get }
	var health: Int { get set }
	var magicResistance: Int { get }
	var defense: Int { get }
}

extension Character {
	var isDead: Bool {
		return health <= 0
	}
}

// MARK: - Fighter
struct Weapon: Equatable {
	let name: String
	let damage: Int
	
	static let sword = Weapon(name: "Sword", damage: 15)
	static let mace = Weapon(name: "Mace", damage: 10)
}

struct Armor: Equatable {
	let name: String
	let defense: Int
	
	static let breastPlate = Armor(name: "Breastplate", defense: 10)
	static let chainMail = Armor(name: "Chainmail", defense: 5)
}

protocol Fighter {
	var weapon: Weapon { get }
	var armor: Armor { get }
}

extension Fighter {
	func attack(_ opponent: Character) -> Character {
		var result = opponent
		let effect = max(0, weapon.damage - opponent.defense)
		result.health -= effect
		return result
	}
}

// MARK: - Spellcaster
struct Spell: Equatable {
	let name: String
	let power: Int
	
	static let fireball = Spell(name: "Fireball", power: 30)
	static let heal = Spell(name: "Heal", power: 20)
}

protocol Spellcaster {
	var spell: Spell { get }
}

extension Spellcaster {
	var isHealer: Bool {
		return spell == .heal
	}
	
	func castSpell(on opponent: Character) -> Character {
		var result = opponent
		let effect = spell.power - opponent.magicResistance
		result.health = isHealer
			? min(opponent.health + effect, type(of: opponent).maxHealth)
			: opponent.health - effect
		return result
	}
}

// MARK: - Concrete types
struct Warrior: Character, Fighter {
	static let maxHealth = 140
	let weapon: Weapon = .sword
	let armor: Armor = .breastPlate
	let magicResistance = 0
	var health = maxHealth
	
	var defense: Int {
		return armor.defense
	}
}

struct Witch: Character, Spellcaster {
	static let maxHealth = 110
	let spell: Spell = .fireball
	let magicResistance = 25
	let defense = 0
	var health = maxHealth
}

struct Cleric: Character, Fighter, Spellcaster {
	static let maxHealth = 100
	let weapon: Weapon = .mace
	let armor: Armor = .chainMail
	let spell: Spell = .heal
	let magicResistance = 10
	var health = maxHealth
	
	var defense: Int {
		return armor.defense
	}
}
