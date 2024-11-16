//
//  BannerCoordinator.swift
//  Skillify
//
//  Created by Ilia Loviagin on 11/16/24.
//

import Foundation
import GoogleMobileAds

class BannerCoordinator: NSObject, GADBannerViewDelegate {
    lazy var bannerView: GADBannerView = {
        let banner = GADBannerView(adSize: parent.adSize)
        banner.adUnitID = self.adId
        banner.load(GADRequest())
        banner.delegate = self
        return banner
    }()

    let parent: BannerView
    let adId: String

    init(_ parent: BannerView, adId: String) {
        self.adId = adId
        self.parent = parent
    }

    // Вывод ошибок
    func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
        print("Failed to load ad: \(error.localizedDescription)")
    }
}
