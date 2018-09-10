// Copyright SIX DAY LLC. All rights reserved.

import Foundation
import UIKit

enum URLServiceProvider {
    case facebook
    case reddit
    case youtube
    case discord
    case twitter
    case medium
    case github

    var title: String {
        switch self {
        case .facebook: return "Facebook"
        case .reddit: return "Reddit"
        case .youtube: return "Youtube"
        case .discord: return "Discord"
        case .twitter: return "Twitter"
        case .medium: return "Medium"
        case .github: return "GitHub"
        }
    }

    var localURL: URL? {
        switch self {
        case .facebook: return URL(string: "fb://profile?id=\(Constants.facebookUsername)")
        case .reddit: return nil
        case .youtube: return URL(string: "youtube://user/\(Constants.youtubeUsername)")!
        case .discord: return nil
        case .twitter: return URL(string: "twitter://user?screen_name=\(Constants.twitterUsername)")!
        case .medium: return nil
        case .github: return nil
        }
    }

    var remoteURL: URL {
        return URL(string: self.remoteURLString)!
    }

    private var remoteURLString: String {
        switch self {
        case .facebook:
            return "https://www.facebook.com/\(Constants.facebookUsername)"
        case .reddit:
            return "https://www.reddit.com/user/MyBit_DApp/"
        case .youtube:
            return "https://www.youtube.com/channel/\(Constants.youtubeUsername)"
        case .discord:
            return "https://discordapp.com/invite/pfNkVkJ"
        case .twitter:
            return "https://twitter.com/\(Constants.twitterUsername)"
        case .medium:
            return "https://medium.com/mybit-dapp"
        case .github:
            return "https://github.com/MyBitFoundation"
        }
    }

    var image: UIImage? {
        switch self {
        case .facebook: return R.image.settings_colorful_facebook()
        case .reddit: return R.image.settings_colorful_reddit()
        case .youtube: return R.image.settings_colorful_youtube()
        case .discord: return R.image.settings_colorful_discord()
        case .twitter: return R.image.settings_colorful_twitter()
        case .medium: return R.image.settings_colorful_medium()
        case .github: return R.image.settings_colorful_github()
        }
    }
}
