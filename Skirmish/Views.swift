//
//  Views.swift
//  Skirmish
//
//  Created by Matteo Manferdini on 17/07/2019.
//  Copyright © 2019 Matteo Manferdini. All rights reserved.
//

import UIKit

@IBDesignable
class GradientView: UIView {
	@IBInspectable var topColor: UIColor = .black
	@IBInspectable var bottomColor: UIColor = .white
	
	override class var layerClass: AnyClass {
		return CAGradientLayer.self
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		(layer as? CAGradientLayer)?.colors = [topColor.cgColor, bottomColor.cgColor]
	}
}

class HealthView: UIProgressView {
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		layer.borderColor = UIColor.black.cgColor
		layer.borderWidth = 1.0
		clipsToBounds = false
	}
}

protocol CharacterViewDelegate: AnyObject {
	func playerDidSelectCharacterView(_ view: CharacterView)
}

class CharacterView: UIStackView {
	@IBOutlet private weak var healthView: HealthView!
	@IBOutlet private weak var characterButton: UIButton!
	
	private var completion: Completion?
	private var maxHealth = 0
	weak var delegate: CharacterViewDelegate?
	
	var member: Game.TeamMember? {
		didSet {
			guard let member = member else { return }
			let color: UIColor = member.team == .player ? .blue : .red
			healthView.tintColor = color
			characterButton.layer.borderColor = color.cgColor
			maxHealth = type(of: member.character).maxHealth
			health = member.character.health
			didMove = member.didMove
			guard let character = member.character as? ImageRepresentable else { return }
			let image = character.image(for: member.team)
			characterButton.setImage(image, for: .normal)
		}
	}
	
	var selected = false {
		didSet { characterButton.layer.borderWidth = selected ? 2.0 : 0.0 }
	}
	
	var didMove: Bool = false {
		didSet {
			guard let member = member else { return }
			characterButton.alpha = member.didMove ? 0.5 : 1.0
		}
	}
	
	var health: Int = 0 {
		didSet {
			healthView.setProgress(Float(self.health) / Float(self.maxHealth), animated: true)
			alpha = member!.character.isDead ? 0.0 : 1.0
		}
	}
	
	@IBAction func selectCharacter(_ sender: Any) {
		delegate?.playerDidSelectCharacterView(self)
	}
	
	func shake(with completion: Completion? ) {
		self.completion = completion
		let animation = CABasicAnimation(keyPath: "position")
		animation.delegate = self
		animation.duration = 0.06
		animation.repeatCount = 4
		animation.autoreverses = true
		let midX = characterButton.center.x
		let midY = characterButton.center.y
		animation.fromValue = CGPoint(x: midX - 5.0, y: midY)
		animation.toValue = CGPoint(x: midX + 5.0, y: midY)
		characterButton.layer.add(animation, forKey: "position")
	}
}

extension CharacterView: CAAnimationDelegate {
	func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
		completion?()
	}
}

protocol ImageRepresentable {}

extension ImageRepresentable {
	func image(for team: Game.Team) -> UIImage {
		var imageName = String(reflecting: Self.self).components(separatedBy: ".").last!
		if team == .opponent {
			imageName.append("-Opponent")
		}
		return UIImage(named: imageName)!
	}
}

extension Warrior: ImageRepresentable {}
extension Witch: ImageRepresentable {}
extension Cleric: ImageRepresentable {}
