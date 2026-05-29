//
//  MyClubsViewController.swift
//  Club
//
//  Created by Manas  on 07/02/26.
//

import UIKit

class MyClubsViewController: UIViewController {
    
    var clubdata: ClubsData!
    var clubdetailData: ClubDetailData!
    var club: [Club] = []
    var ClubsRecommended: [Club] = []
    var ClubsMy: [Club] = []
    var ClubsTrending: [Club] = []
    
    var sectionType: ClubSection = .trending
    
    
    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        switch sectionType {
        case .myClubs:
            club = clubdata.clubs(for: .myClubs)
            title = "My Clubs"
            
        case .recommended:
            club = clubdata.clubs(for: .recommended)
            title = "Recommended"
            
        case .trending:
            club = clubdata.clubs(for: .trending)
            title = "Trending"
        }

        tableView.dataSource = self
        tableView.delegate = self
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Refresh data every time screen appears
        club = clubdata.clubs(for: sectionType)
        tableView.reloadData()
    }
    
    @IBAction func unwindToClubViewController(_ unwindSegue: UIStoryboardSegue) {

        guard unwindSegue.identifier == "saveUnwind",
              let source = unwindSegue.source as? CreateClubTableViewController,
              let newClub = source.club else { return }

        // Add new club to My Clubs (Section 0)
        clubdata.addClub(newClub)
        
        // update local array
        club = clubdata.clubs(for: sectionType)

        
        tableView.reloadData()
        }
        
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showClubDetail",
           let vc = segue.destination as? KafkaViewController,
           let cell = sender as? UITableViewCell,
           let indexPath = tableView.indexPath(for: cell) {
            
            let selectedClub = club[indexPath.row]
            vc.clubId = selectedClub.id ?? ""
            vc.club = selectedClub
            vc.clubDetailData = self.clubdetailData
            vc.clubData = self.clubdata
            vc.hidesBottomBarWhenPushed = true
        }
    }
}

extension MyClubsViewController: UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return club.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! CustomTableViewCell
        
        let clubItem = club[indexPath.row]
        if let path = clubItem.imagePath, !path.isEmpty {
            if path.hasPrefix("http") {
                cell.iconimageView.loadFromUrl(path, placeholder: nil)
            } else if let img = UIImage(named: path) {
                cell.iconimageView.image = img
            } else if let docURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let fileURL = docURL.appendingPathComponent(path)
                cell.iconimageView.image = UIImage(contentsOfFile: fileURL.path)
            }
        } else {
            cell.iconimageView.image = nil
        }
        
        cell.iconimageView.layer.cornerRadius = 24
        cell.titlelabel.text = clubItem.name
        cell.desc.text = clubItem.description
        cell.genre.text = clubItem.category?.displayName
        
        //giving shadow and radius to the view
        cell.view.layer.cornerRadius = 24
        cell.view.layer.masksToBounds = false
//        cell.layer.shadowColor = UIColor.black.cgColor
//        cell.layer.shadowOpacity = 0.18
//        cell.layer.shadowOffset = CGSize(width: 0, height: 6)
//        cell.layer.shadowRadius = 12
//        cell.layer.shadowPath = UIBezierPath(
//            roundedRect: cell.bounds,
//            cornerRadius: 16
//        ).cgPath
        
        return cell
    }
}
extension MyClubsViewController: UITableViewDelegate{
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 165
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
