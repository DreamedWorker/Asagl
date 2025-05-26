//
//  LauncherNews.swift
//  Asagl
//
//  Created by Yuan Shine on 2025/5/10.
//

// MARK: - LauncherNews
struct LauncherNews: Codable, Equatable {
    let retcode: Int
    let message: String
    let data: DataClass
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.data.content.game.biz == rhs.data.content.game.biz
    }
}

extension LauncherNews {
    // MARK: - DataClass
    struct DataClass: Codable {
        let content: Content
    }
    
    // MARK: - Content
    struct Content: Codable {
        let game: Game
        let language: String
        let banners: [Banner]
        let posts: [Post]
        let socialMediaList: [SocialMediaList]
        
        enum CodingKeys: String, CodingKey {
            case game, language, banners, posts
            case socialMediaList = "social_media_list"
        }
    }
    
    // MARK: - Banner
    struct Banner: Codable {
        let id: String
        let image: Image
        let i18NIdentifier: String
        
        enum CodingKeys: String, CodingKey {
            case id, image
            case i18NIdentifier = "i18n_identifier"
        }
    }
    
    // MARK: - Image
    struct Image: Codable {
        let url: String
        let link: String
        let loginStateInLink: Bool
        
        enum CodingKeys: String, CodingKey {
            case url, link
            case loginStateInLink = "login_state_in_link"
        }
    }
    
    // MARK: - Game
    struct Game: Codable {
        let id, biz: String
    }
    
    // MARK: - Post
    struct Post: Codable {
        let id, type, title: String
        let link: String
        let date: String
        let loginStateInLink: Bool
        let i18NIdentifier: String
        
        enum CodingKeys: String, CodingKey {
            case id, type, title, link, date
            case loginStateInLink = "login_state_in_link"
            case i18NIdentifier = "i18n_identifier"
        }
    }
    
    // MARK: - SocialMediaList
    struct SocialMediaList: Codable {
        let id: String
        let icon: Icon
        let qrImage: Image
        let qrDesc: String
        let links: [Link]
        let enableRedDot: Bool
        let redDotContent: String
        
        enum CodingKeys: String, CodingKey {
            case id, icon
            case qrImage = "qr_image"
            case qrDesc = "qr_desc"
            case links
            case enableRedDot = "enable_red_dot"
            case redDotContent = "red_dot_content"
        }
    }
    
    // MARK: - Icon
    struct Icon: Codable {
        let url: String
        let hoverURL: String
        let link: String
        let loginStateInLink: Bool
        let md5: String
        let size: Int
        
        enum CodingKeys: String, CodingKey {
            case url
            case hoverURL = "hover_url"
            case link
            case loginStateInLink = "login_state_in_link"
            case md5, size
        }
    }
    
    // MARK: - Link
    struct Link: Codable {
        let title: String
        let link: String
        let loginStateInLink: Bool
        
        enum CodingKeys: String, CodingKey {
            case title, link
            case loginStateInLink = "login_state_in_link"
        }
    }
}
