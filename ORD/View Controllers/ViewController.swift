//
//  ViewController.swift
//  ordtest
//
//  Created by Joel Wong on 8/1/20.
//  Copyright © 2020 Joel Wong. All rights reserved.
//

import UIKit
import FloatingPanel
import MKRingProgressView
import CoreData

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, DestinationViewControllerDelegate,FloatingPanelControllerDelegate{

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let nav = segue.destination as? UINavigationController, let settingsViewController = nav.topViewController as? settingsViewController {
            settingsViewController.delegate = self
        }
    }
    
    // Update after change in dates or events
    func updateData() {
        calculateLeave(endDate: defaults.value(forKey: "ordDate") as? Date ?? date)
        createDataArray()
        displayInfo()
        self.collectionView.reloadData()
    }
    
    @IBOutlet weak var progressRing: RingProgressView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet var dateCount: UILabel!
    @IBOutlet weak var daysToORD: UILabel!
    
    var fpc: FloatingPanelController!
    var searchVC: SearchPanelViewController!
    
    var ordDays: String = ""
    var popDays: String = ""
    var daysToOrdLabel: String = ""
    var daysToPopLabel: String = ""
    var isTextOne = true
    
    // Generate data for collection view
    let tileNames = ["Working Days", "Completed", "Leave", "Off"]
    let cellIcons = ["calendar.circle.fill", "checkmark.circle.fill", "bolt.circle.fill", "heart.circle.fill"]
    var colors: [UIColor] = [.systemRed, .systemOrange, .systemBlue, .systemGreen]
    var dataArray: [String] = []
    
    let defaults = UserDefaults.standard
    private let spacing:CGFloat = 22.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        DataManager.shared.homeVC = self
        collectionView.dataSource = self
        collectionView.delegate = self

        // Create transparent Navigation Bar
        self.navigationController!.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController!.navigationBar.shadowImage = UIImage()
        self.navigationController!.navigationBar.isTranslucent = true
        
        // Create tile view
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: spacing, left: spacing, bottom: spacing, right: spacing)
        layout.minimumLineSpacing = spacing
        layout.minimumInteritemSpacing = spacing
        self.collectionView?.collectionViewLayout = layout
        
        // Create Floating Panel Controller
        fpc = FloatingPanelController()
        fpc.delegate = self
        
        fpc.surfaceView.backgroundColor = .clear
        fpc.surfaceView.cornerRadius = 15.0
        fpc.surfaceView.shadowHidden = false
        fpc.surfaceView.borderWidth = 1.0 / traitCollection.displayScale
        fpc.surfaceView.borderColor = UIColor.black.withAlphaComponent(0.2)

        searchVC = storyboard?.instantiateViewController(withIdentifier: "SearchPanel") as? SearchPanelViewController

        fpc.set(contentViewController: searchVC)
        fpc.track(scrollView: searchVC.tableView)
        
        createDataArray()
        displayInfo()
        
        Timer.scheduledTimer(withTimeInterval: 3, repeats: true) {_ in
            self.dateCount.text = self.isTextOne ? self.popDays:self.ordDays
            self.daysToORD.text = self.isTextOne ? self.daysToPopLabel:self.daysToOrdLabel
            self.isTextOne = !self.isTextOne
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        fpc.addPanel(toParent: self, animated: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        fpc.removePanelFromParent(animated: true)
    }
        
    func displayInfo() {
        let ord = defaults.value(forKey: "ordDate") as? Date ?? date
        let pop = defaults.value(forKey: "popDate") as? Date ?? date
        let daysToPop = daysCounter(from: date, until: pop)
        let progress = progressCounter(from: date, until: ord)
        if progress >= 1 {
            progressRing.progress = 1
            ordDays = "ORD LO"
            popDays = ordDays
            self.dateCount.adjustsFontSizeToFitWidth = true
            daysToOrdLabel = "Where Got Time"
            daysToPopLabel = daysToOrdLabel
            self.dateCount.text = "ORD LO"
            self.daysToORD.text = "Where Got Time"
        } else {
            ordDays = "\(daysCounter(from: date, until: ord))"
            popDays = ordDays
            daysToOrdLabel = "days to ORD"
            daysToPopLabel = "days to ORD"
            self.daysToORD.text = daysToOrdLabel
            self.dateCount.text = ordDays
            self.dateCount.adjustsFontSizeToFitWidth = true
            progressRing.progress = Double(progress)
            if daysToPop >= 0{
                popDays = "\(daysToPop)"
                daysToPopLabel = "days to POP"
            }
        }
    }
    
    func createDataArray() {
        dataArray = []
        let ord = defaults.value(forKey: "ordDate") as? Date ?? date
        
        // Set default off
        if defaults.value(forKey: "off") == nil {
            defaults.set(0, forKey: "off")
        }
        
        let year = defaults.integer(forKey: "year")
        let currentYear = calendar.component(.year, from: date)
        if year != currentYear {
            calculateLeave(endDate: ord)
            defaults.set(currentYear, forKey: "year")
        }
        //defaults.set(0, forKey: "offUsed")
        //defaults.set(0, forKey: "leaveUsed")
        let progress = progressCounter(from: date, until: ord)
        let leaveLeft = defaults.double(forKey: "leave")
        let offLeft = defaults.double(forKey: "off")
        let upcomingLeave = defaults.double(forKey: "upcomingLeave")
        let upcomingOff = defaults.double(forKey: "upcomingOff")
        if progress >= 1 {
            dataArray += ["0", "100%", "0", "0"]
        } else {
            let workingDays1 = workingDaysCounter(from: date, until: ord) - leaveLeft - offLeft
            let workingDays2 = workingDays1 - upcomingLeave - upcomingOff - 1
            let workingDays = String(format:"%g", workingDays2)
            if progress <= 0 {
                dataArray += [workingDays, "0%", String(format:"%g",leaveLeft), "0"]
            }
            else {
                let percentageComplete = String(format: "%.1f%%", progress*100)
                dataArray += [workingDays, percentageComplete, String(format:"%g",leaveLeft), String(format:"%g",offLeft)]
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tileNames.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! CollectionViewCell
        cell.daysLabel.text = dataArray[indexPath.row]
        cell.titleLabel.text = tileNames[indexPath.row]
        let icon = UIImage(systemName: "\(cellIcons[indexPath.row])")!.withTintColor(colors[indexPath.row])
        let size = CGSize(width: 35, height: 34)
        cell.cellIcon.image = UIGraphicsImageRenderer(size:size).image {
            _ in icon.draw(in:CGRect(origin:.zero, size:size))
        }
        cell.contentView.layer.cornerRadius = 10.0
        cell.contentView.layer.borderWidth = 1.0
        cell.contentView.layer.borderColor = UIColor.clear.cgColor
        cell.contentView.layer.masksToBounds = false
        cell.layer.masksToBounds = false
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch indexPath.row {
        case 2:
            performSegue(withIdentifier: "showLeave", sender: (Any).self)
        case 3:
            performSegue(withIdentifier: "showOff", sender: (Any).self)
        default:
            return
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? CollectionViewCell {
            cell.contentView.backgroundColor = colors[indexPath.row]
            cell.titleLabel.textColor = .white
            cell.daysLabel.textColor = .white
            let icon = UIImage(systemName: "\(cellIcons[indexPath.row])")!.withTintColor(.white)
            let size = CGSize(width: 35, height: 34)
            cell.cellIcon.image = UIGraphicsImageRenderer(size:size).image {
                _ in icon.draw(in:CGRect(origin:.zero, size:size))
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? CollectionViewCell {
            cell.contentView.backgroundColor = .secondarySystemGroupedBackground
            cell.titleLabel.textColor = .secondaryLabel
            cell.daysLabel.textColor = .label
            let icon = UIImage(systemName: "\(cellIcons[indexPath.row])")!.withTintColor(colors[indexPath.row])
            let size = CGSize(width: 35, height: 34)
            cell.cellIcon.image = UIGraphicsImageRenderer(size:size).image {
                _ in icon.draw(in:CGRect(origin:.zero, size:size))
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let numberOfItemsPerRow:CGFloat = 2
        let spacingBetweenCells:CGFloat = 22
        
        let totalSpacing = (2 * self.spacing) + ((numberOfItemsPerRow - 1) * spacingBetweenCells) //Amount of total spacing in a row
        
        if let collection = self.collectionView{
            let width = (collection.bounds.width - totalSpacing)/numberOfItemsPerRow
            return CGSize(width: width, height: 85)
        }else{
            return CGSize(width: 0, height: 0)
        }
    }

    // MARK: FloatingPanelControllerDelegate
    
    func floatingPanel(_ vc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout? {
        fpc.surfaceView.borderWidth = 0.0
        fpc.surfaceView.borderColor = nil
        return MyFloatingPanelLayout()
    }

    func floatingPanelDidMove(_ vc: FloatingPanelController) {
        let y = vc.surfaceView.frame.origin.y
        let tipY = vc.originYOfSurface(for: .tip)
        if y > tipY - 44.0 {
            let progress = max(0.0, min((tipY  - y) / 44.0, 1.0))
            self.searchVC.tableView.alpha = progress
        }
    }

    func floatingPanelWillBeginDragging(_ vc: FloatingPanelController) {
        if vc.position == .full {
        }
    }

    func floatingPanelDidEndDragging(_ vc: FloatingPanelController, withVelocity velocity: CGPoint, targetPosition: FloatingPanelPosition) {
        UIView.animate(withDuration: 0.25,
                       delay: 0.0,
                       options: .allowUserInteraction,
                       animations: {
                        if targetPosition == .tip {
                            self.searchVC.tableView.alpha = 0.0
                        } else {
                            self.searchVC.tableView.alpha = 1.0
                        }
        }, completion: nil)
    }
}

class MyFloatingPanelLayout: FloatingPanelLayout {
    public var initialPosition: FloatingPanelPosition {
        return .tip
    }

    public func insetFor(position: FloatingPanelPosition) -> CGFloat? {
        switch position {
            case .full: return 16.0 // A top inset from safe area
            case .half: return 270.0 // A bottom inset from the safe area
            case .tip: return 60.0 // A bottom inset from the safe area
            default: return nil // Or `case .hidden: return nil`
        }
    }
}
