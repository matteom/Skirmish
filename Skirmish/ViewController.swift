//
//  ViewController.swift
//  Skirmish
//
//  Created by Matteo Manferdini on 15/07/2019.
//  Copyright © 2019 Matteo Manferdini. All rights reserved.
//

import UIKit

typealias Completion = () -> Void

class ViewController: UIViewController {
	@IBOutlet var playerViews: [CharacterView]!
	@IBOutlet var opponentViews: [CharacterView]!
	@IBOutlet var actionButtons: [UIButton]!
	
	private var game = Game()
	private var state: State = .noSelection
	
	var characterViews: [CharacterView] {
		return playerViews + opponentViews
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		populateCharacterViews(playerViews, with: game.playerTeam)
		populateCharacterViews(opponentViews, with: game.opponentTeam)
		populateActionButtons(with: [])
	}
	
	@IBAction func selectAction(_ sender: UIButton) {
		guard case .selectedTeamMember(let teamMember) = state else { return }
		guard let index = actionButtons.firstIndex(of: sender) else { return }
		let selectedAction = teamMember.actions[index]
		state = .selectedAction(teamMember: teamMember, action: selectedAction)
	}
}

extension ViewController: CharacterViewDelegate {
	func playerDidSelectCharacterView(_ view: CharacterView) {
		guard game.turn == .player else { return }
		switch state {
		case .noSelection, .selectedTeamMember:
			selectTeamMember(for: view)
		case .selectedAction(let teamMember, let action):
			let target = self.teamMember(for: view)
			let playerMove = Game.Move(performer: teamMember, target: target, action: action)
			perform(playerMove) {
				DispatchQueue.global(qos: .userInitiated).async {
					let opponentMove = self.game.nextPly()
					DispatchQueue.main.async {
						let view = self.view(for: opponentMove.performer)
						view.selected = true
						self.perform(opponentMove, withCompletion: nil)
					}
				}
			}
		}
	}
}

private extension ViewController {
	func populateCharacterViews(_ views: [CharacterView], with members: [Game.TeamMember]) {
		for (index, member) in members.enumerated() {
			let view = views[index]
			view.member = member
			view.delegate = self
		}
	}
	
	func populateActionButtons(with actions: [Game.Action]) {
		for (index, button) in actionButtons.enumerated() {
			guard index < actions.count else {
				button.setTitle(nil, for: .normal)
				continue
			}
			let action = actions[index]
			button.setTitle(action.name, for: .normal)
		}
	}
	
	func selectTeamMember(for view: CharacterView) {
		guard playerViews.contains(view) else { return }
		let teamMember = self.teamMember(for: view)
		guard !teamMember.didMove else { return }
		deselectAllViews()
		view.selected = true
		populateActionButtons(with: teamMember.actions)
		state = .selectedTeamMember(teamMember: teamMember)
	}
	
	func perform(_ move: Game.Move, withCompletion completion: Completion?) {
		let targetView = view(for: move.target)
		targetView.shake {
			self.game.perform(move)
			self.characterViews.forEach { $0.member = self.teamMember(for: $0) }
			self.deselectAllViews()
			self.populateActionButtons(with: [])
			self.state = .noSelection
			completion?()
		}
	}
	
	func deselectAllViews() {
		characterViews.forEach { $0.selected = false }
	}
	
	func teamMember(for view: CharacterView) -> Game.TeamMember {
		return game.members.first { $0.id == view.member!.id }!
	}
	
	func view(for teamMember: Game.TeamMember) -> CharacterView {
		return characterViews.first(where: { $0.member!.id == teamMember.id })!
	}
}

extension ViewController {
	enum State {
		case noSelection
		case selectedTeamMember(teamMember: Game.TeamMember)
		case selectedAction(teamMember: Game.TeamMember, action: Game.Action)
	}
}
