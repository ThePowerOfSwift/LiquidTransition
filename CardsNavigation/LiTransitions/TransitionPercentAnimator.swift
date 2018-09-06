//
//  TransitionPercentAnimator.swift
//  CardsNavigation
//
//  Created by Alexander Graschenkov on 22.08.2018.
//  Copyright © 2018 Alex Development. All rights reserved.
//

import UIKit

protocol TransitionPercentAnimatorDelegate: class {
    func transitionPercentChanged(_ percent: CGFloat)
}

class InvertableInteractiveTransition: UIPercentDrivenInteractiveTransition {
    var backward = false
    private(set) var percent: CGFloat = 0
    
    override var percentComplete: CGFloat {
        get { return backward ? 1.0-super.percentComplete : super.percentComplete }
    }
    override func update(_ percentComplete: CGFloat) {
        percent = percentComplete
        var val = backward ? 1.0-percentComplete : percentComplete
        val = min(val, 0.999)
        super.update(val)
//        print(val, super.percentComplete)
    }
}

class TransitionPercentAnimator: InvertableInteractiveTransition {
    
    fileprivate var cancelAnimation: Cancelable?
    fileprivate(set) var lastSpeed: CGFloat = 0
    fileprivate(set) var lastUpdateTime: TimeInterval = 0
    weak var context: UIViewControllerContextTransitioning?
    var totalDuration: Double = 0
    
    weak var delegate: TransitionPercentAnimatorDelegate?
    
    func animate(finish: Bool, speed: CGFloat = 0) {
        cancelAnimation?()
        
        let fromPercent = percent
        let toPercent: CGFloat = finish ? 1.0 : 0.0
        var speedUp: CGFloat = 1.0
        if speed > 0 {
            speedUp = speed
        }
        let animDuration = duration * abs(toPercent - fromPercent) / speedUp
        
        cancelAnimation = DisplayLinkAnimator.animate(duration: Double(animDuration), closure: { (percent) in
            super.update(percent)
            self.delegate?.transitionPercentChanged(percent)
            if (percent == toPercent) {
                if finish {
                    self.finish()
                } else {
                    self.cancel()
                }
                
                self.context?.completeTransition(finish)
//                self.context?.completeTransition(finish)
            }
        })
    }
    
    func pauseAnimation() {
        cancelAnimation?()
        cancelAnimation = nil
    }
    
    override func update(_ percentComplete: CGFloat) {
        cancelAnimation?()
        cancelAnimation = nil
        
        updateSpeedWith(percentComplete: percentComplete)
        super.update(percentComplete)
        delegate?.transitionPercentChanged(percent)
    }
    
    func needFinish() -> Bool {
        if lastSpeed == 0 {
            return percent > 0.4
        } else {
            return lastSpeed > 0
        }
    }
    
    fileprivate func updateSpeedWith(percentComplete: CGFloat) {
        let currTime = CACurrentMediaTime()
        if lastUpdateTime == 0 {
            if (percentComplete - self.percentComplete) > 0 {
                lastSpeed = 1.0 / duration
            } else {
                lastSpeed = -1.0 / duration
            }
        } else {
            lastSpeed = (percentComplete - self.percentComplete) / CGFloat(currTime - lastUpdateTime)
        }
        lastUpdateTime = currTime
    }
    
    internal func reset() {
        lastSpeed = 0
        lastUpdateTime = 0
        backward = false
    }
}
