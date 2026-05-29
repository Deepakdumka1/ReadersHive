//
//  MemberListVC.swift
//  Club
//
//  Created by Manas  on 23/03/26.
//

import Foundation
import UIKit
import FirebaseFirestore

class MemberListVC: UIViewController {

    @IBOutlet weak var memberTableView: UITableView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var searchBar: UISearchBar!

    var members: [ClubMember] = []
    var clubName: String = ""
    var isAdmin: Bool = false
    var clubData: ClubsData!
    var clubId: String = ""

    private var memberProfiles: [Profile] = []
    private var filteredProfiles: [Profile] = []
    private var isSearching = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeTapped)
        )

        // Filter out duplicate UIDs from the members array
        var uniqueMembers: [ClubMember] = []
        var seenIds = Set<String>()
        for member in members {
            if !seenIds.contains(member.userId) {
                uniqueMembers.append(member)
                seenIds.insert(member.userId)
            }
        }
        self.members = uniqueMembers

        memberTableView.delegate = self
        memberTableView.dataSource = self
        memberTableView.separatorStyle = .none
        memberTableView.rowHeight = 80

        nameLabel.text = clubName
        countLabel.text = "\(members.count) members"
        searchBar.delegate = self
        
        fetchMemberProfiles()
    }

    private func fetchMemberProfiles() {
        let db = Firestore.firestore()
        Task {
            var fetched: [Profile] = []
            for member in members {
                let uid = member.userId
                if let doc = try? await db.collection("profiles").document(uid).getDocument(),
                   let profile = try? doc.data(as: Profile.self) {
                    fetched.append(profile)
                } else {
                    // Use cached name if profile doc is missing
                    let name = member.fullName ?? "User"
                    fetched.append(Profile(id: uid, userId: uid, fullName: name, username: name, bio: nil, avatarUrl: nil, visibility: "public", followers: [], following: []))
                }
            }
            
            DispatchQueue.main.async {
                self.memberProfiles = fetched
                self.filteredProfiles = fetched
                self.memberTableView.reloadData()
            }
        }
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
}

// MARK: - UITableViewDelegate
extension MemberListVC: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
}

// MARK: - UITableViewDataSource
extension MemberListVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredProfiles.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CustomMemberListCell", for: indexPath) as! MemberListTableViewCell
        let profile = filteredProfiles[indexPath.row]
        cell.configure(withProfile: profile, isAdmin: isAdmin)
        cell.removeDelegate = self
        return cell
    }
}

// MARK: - UISearchBarDelegate
extension MemberListVC: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            isSearching = false
            filteredProfiles = memberProfiles
        } else {
            isSearching = true
            filteredProfiles = memberProfiles.filter { 
                $0.fullName.localizedCaseInsensitiveContains(searchText) || 
                $0.username.localizedCaseInsensitiveContains(searchText)
            }
        }
        memberTableView.reloadData()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

// MARK: - MemberRemoveDelegate
extension MemberListVC: MemberRemoveDelegate {
    func didTapRemove(userId: String) {
        clubData.removeMember(clubId: clubId, userId: userId)
        members.removeAll(where: { $0.userId == userId })
        memberProfiles.removeAll(where: { $0.userId == userId })
        filteredProfiles.removeAll(where: { $0.userId == userId })
        countLabel.text = "\(members.count) members"
        memberTableView.reloadData()
    }
}
