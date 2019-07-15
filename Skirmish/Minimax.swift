//
//  Minimax.swift
//  Skirmish
//
//  Created by Matteo Manferdini on 22/07/2019.
//  Copyright © 2019 Matteo Manferdini. All rights reserved.
//

import Foundation

protocol Minimaxable {
	associatedtype Ply
	var isTerminal: Bool { get }
	func heuristicValue(maximizingPlayer: Bool) -> Int
	func possiblePlies() -> [Ply]
	func state(performing ply: Ply) -> Self
}

struct EvaluatedPly<P> {
	let value: Int
	let ply: P?
}

extension EvaluatedPly: Comparable {
	static func < (lhs: EvaluatedPly<P>, rhs: EvaluatedPly<P>) -> Bool {
		return lhs.value < rhs.value
	}
	
	static func == (lhs: EvaluatedPly<P>, rhs: EvaluatedPly<P>) -> Bool {
		return lhs.value == rhs.value
	}
}

extension Minimaxable {
	func minimax(atDepth depth: Int, maximizingPlayer: Bool) -> EvaluatedPly<Ply> {
		if depth == 0 || isTerminal {
			return EvaluatedPly(value: heuristicValue(maximizingPlayer: maximizingPlayer), ply: nil)
		}
		var bestPly: EvaluatedPly<Ply> = EvaluatedPly(value: maximizingPlayer ? Int.min : Int.max, ply: nil)
		for ply in possiblePlies() {
			let state = self.state(performing: ply)
			let evaluatedPly = state.minimax(atDepth: depth - 1, maximizingPlayer: !maximizingPlayer)
			let currentPly = EvaluatedPly(value: evaluatedPly.value, ply: ply)
			bestPly = maximizingPlayer ? max(currentPly, bestPly) : min(currentPly, bestPly)
		}
		return bestPly
	}
	
	func nextPly() -> Ply {
		let evaluatedPly = minimax(atDepth: 3, maximizingPlayer: true)
		return evaluatedPly.ply!
	}
}

extension Game: Minimaxable {
	var isTerminal: Bool {
		return playerTeam.count == 0 || opponentTeam.count == 0
	}
	
	func heuristicValue(maximizingPlayer: Bool) -> Int {
		var healthScore = 0
		for member in members.filter({ !$0.character.isDead }) {
			let maximizingTeam = maximizingPlayer ? self.turn : self.turn.other
			let sign = member.team == maximizingTeam ? 1 : -1
			healthScore += sign * member.character.health
		}
		return healthScore
	}
	
	func state(performing ply: Game.Move) -> Game {
		var state = self
		state.perform(ply)
		return state
	}
	
	func possiblePlies() -> [Game.Move] {
		let attacker = turn == .player ? playerTeam : opponentTeam
		let defender = turn == .player ? opponentTeam : playerTeam
		var moves: [Game.Move] = []
		for member in attacker {
			guard !member.didMove else { continue }
			for action in member.actions {
				moves += action.isAttack
					? defender.map { Move(performer: member, target: $0, action: action) }
					: attacker.map { Move(performer: member, target: $0, action: action) }
			}
		}
		return moves
	}
}

extension Game.Team {
	var other: Game.Team {
		return self == .player ? .opponent : .player
	}
}
