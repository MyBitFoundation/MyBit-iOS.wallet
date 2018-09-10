// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import UIKit

class NoInternetView: UIView {
    
    var label: UILabel?
    var redView: UIView?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        configView()
        createRedViewIfNeeded()
        createLabelIfNeeded()
    }
    
    func configView() {
        
        backgroundColor = UIColor.clear
        
        layer.shadowColor = UIColor(red: 0.00, green: 0.00, blue: 0.00, alpha: 0.8).cgColor
        layer.shadowOpacity = 0.3
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 3
    }
    
    func createRedViewIfNeeded() {
        
        if self.redView != nil {
            return
        }
        
        let view = UIView()
        view.backgroundColor = UIColor(hex: "e33450")
        view.layer.cornerRadius = 3
        view.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(view)
        
        let topConstraint = NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1.0, constant: 0)
        let bottomConstraint = NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1.0, constant: 0)
        let leftConstraint = NSLayoutConstraint(item: self, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 0)
        let rightConstraint = NSLayoutConstraint(item: self, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: 0)
        
        addConstraints([topConstraint, bottomConstraint, leftConstraint, rightConstraint])
        
        self.redView = view
        
    }
    
    func createLabelIfNeeded() {
        
        if self.label != nil {
            return
        }
        
        let label = UILabel()
        label.textColor = UIColor.white
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 2
        label.text = R.string.localizable.noInternetLabelTitle()
        label.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(label)
        
        let topConstraint = NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: label, attribute: .top, multiplier: 1.0, constant: -10)
        let bottomConstraint = NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: label, attribute: .bottom, multiplier: 1.0, constant: 10)
        let leftConstraint = NSLayoutConstraint(item: self, attribute: .left, relatedBy: .equal, toItem: label, attribute: .left, multiplier: 1.0, constant: -16)
        let rightConstraint = NSLayoutConstraint(item: self, attribute: .right, relatedBy: .equal, toItem: label, attribute: .right, multiplier: 1.0, constant: 16)
        
        addConstraints([topConstraint, bottomConstraint, leftConstraint, rightConstraint])
        
        self.label = label
    }
}
