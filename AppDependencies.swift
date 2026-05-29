//
//  AppDependencies.swift
//  Club
//
//  Created by Manas  on 15/03/26.
//

//AppDependencies container to manage all shared data models in one place.
import Foundation

class AppDependencies {
    
    static var shared = AppDependencies()
    
    static func reset() {
        shared = AppDependencies()
    }
    
    let messageDataModel: MessageDataModel
    let clubData: ClubsData
    let bookshelfData: BookshelfData
    let trendingBooksData: TrendingData
    let feedData: FeedData
    let suggestionData: SuggestedData
    let clubdetailData: ClubDetailData
    let userData: UserData
    let profileData: ProfileData
    
    // New dependency for the profile screen
    let profileScreenData: ProfileScreenModel
    let followRepository: FollowRepository

    
    private init() {
        self.messageDataModel = MessageDataModel()
        self.clubData = ClubsData()
        self.bookshelfData = BookshelfData()
        self.trendingBooksData = TrendingData()
        self.feedData = FeedData()
        self.suggestionData = SuggestedData()
        self.clubdetailData = ClubDetailData()
        self.userData = UserData()
        self.profileData = ProfileData()
        self.profileScreenData = ProfileScreenModel()
        self.followRepository = FollowRepository()
    }
}
