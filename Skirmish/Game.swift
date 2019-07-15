//
//  Game.swift
//  Skirmish
//
//  Created by Matteo Manferdini on 15/07/2019.
//  Copyright © 2019 Matteo Manferdini. All rights reserved.
//

import Foundation

struct Game {
	var turn = Team.player
	var members = makeTeam(.player) + makeTeam(.opponent)
	
	var playerTeam: [TeamMember] {
		return members.filter { $0.team == .player }
	}
	
	var opponentTeam: [TeamMember] {
		return members.filter { $0.team == .opponent }
	}
	
	mutating func perform(_ move: Move) {
		func update(_ member: TeamMember) {
			guard let index = members.firstIndex(where: { $0.id == member.id }) else { return }
			members[index] = member
		}
		
		func startNewRound() {
			for var member in members {
				member.didMove = false
				update(member)
			}
		}
		
		var teamMember = move.performer
		teamMember.didMove = true
		update(teamMember)
		var target = move.target.id == teamMember.id ? teamMember : move.target
		target.character = move.action.closure(target.character)
		update(target)
		turn = turn.other
		let roundEnded = members.filter({ !$0.didMove }).isEmpty
		if roundEnded {
			startNewRound()
		}
	}
}

extension Game {
	enum Team {
		case player
		case opponent
	}
	
	struct TeamMember {
		let id = UUID()
		let team: Team
		var character: Character
		var didMove = false
		
		var actions: [Action] {
			return (character as? Actionable)?.actions ?? []
		}
	}
	
	struct Action {
		let name: String
		let closure: (Character) -> Character
		let isAttack: Bool
	}
	
	struct Move {
		let performer: TeamMember
		let target: TeamMember
		let action: Action
	}
}

private extension Game {
	static func makeTeam(_ team: Team) -> [TeamMember] {
		func makeCharacters<C: Initializable>(from: Int, upTo: Int) -> [C] {
			return (0 ..< Int.random(in: from...upTo)).map { _ in C.init() }
		}
		
		let witches: [Witch] = makeCharacters(from: 1, upTo: 2)
		let clerics: [Cleric] = makeCharacters(from: 1, upTo: 2)
		let teamCount = 5
		let remaining = teamCount - witches.count - clerics.count
		let warriors: [Warrior] = makeCharacters(from: remaining, upTo: remaining)
		let allCharacters: [Character] = witches + clerics + warriors
		return allCharacters
			.shuffled()
			.map { TeamMember(team: team, character: $0, didMove: false) }
	}
}

// MARK: - Initializable
protocol Initializable {
	init()
}

extension Warrior: Initializable {}
extension Witch: Initializable {}
extension Cleric: Initializable {}

// MARK: - Actionable
protocol Actionable {
	var actions: [Game.Action] { get }
}

extension Fighter {
	var attackAction: Game.Action {
		return Game.Action(name: "Attack", closure: attack(_:), isAttack: true)
	}
}

extension Spellcaster {
	var spellAction: Game.Action {
		return Game.Action(name: spell.name, closure: castSpell(on:), isAttack: !isHealer)
	}
}

extension Warrior: Actionable {
	var actions: [Game.Action] {
		return [attackAction]
	}
}

extension Witch: Actionable {
	var actions: [Game.Action] {
		return [spellAction]
	}
}

extension Cleric: Actionable {
	var actions: [Game.Action] {
		return [attackAction, spellAction]
	}
}
