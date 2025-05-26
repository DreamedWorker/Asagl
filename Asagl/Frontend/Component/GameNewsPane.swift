//
//  GameNewsPane.swift
//  Asagl
//
//  Created by Yuan Shine on 2025/5/10.
//

import SwiftUI
import Kingfisher
import GameKit

struct GameNewsPane: View {
    let gameType: GameKit.GameType
    @State private var news: LauncherNews? = nil
    @StateObject private var svm = SharedViewModel.shared
    @State private var currentIndex = 0
    @State private var timer: Timer? = nil
    @State private var selectedScope: NewsType = .Activity
    @State private var selectedPosts: [LauncherNews.Post] = []
    
    var body: some View {
        VStack {
            if let news = news {
                let banner = news.data.content.banners[currentIndex]
                KFImage.url(URL(string: banner.image.url))
                    .loadDiskFileSynchronously(true)
                    .resizable()
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    //.aspectRatio(1.7, contentMode: .fit)
                    .frame(width: 420, height: 180)
                    .onTapGesture {
                        openBrowser(website: banner.image.link)
                    }
                    .onAppear {
                        startTimer(news: news)
                    }
                    .onChange(of: news, {_, new in
                        currentIndex = 0
                        timer?.invalidate()
                        startTimer(news: new)
                    })
                VStack {
                    HStack(spacing: 8) {
                        NewsTypeIndicator(title: NSLocalizedString("news.tab.activity", comment: ""), showSelected: selectedScope == NewsType.Activity)
                            .onTapGesture {
                                selectedScope = .Activity
                            }
                        NewsTypeIndicator(title: NSLocalizedString("news.tab.notice", comment: ""), showSelected: selectedScope == NewsType.Notice)
                            .onTapGesture {
                                selectedScope = .Notice
                            }
                        NewsTypeIndicator(title: NSLocalizedString("news.tab.info", comment: ""), showSelected: selectedScope == NewsType.Info)
                            .onTapGesture {
                                selectedScope = .Info
                            }
                        Spacer()
                    }
                    .frame(height: 30)
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack {
                            ForEach(selectedPosts, id: \.id) { post in
                                HStack {
                                    Text(post.title).foregroundStyle(.white)
                                    Spacer()
                                    Text(post.date).foregroundStyle(.white.opacity(0.85))
                                }
                                .padding(.vertical, 4)
                                .onTapGesture {
                                    openBrowser(website: post.link)
                                }
                            }
                        }
                        .padding(.horizontal, 8)
                        .onAppear {
                            selectedPosts = news.data.content.posts.filter({ $0.type == selectedScope.rawValue })
                        }
                        .onChange(of: news, {_, new in
                            selectedPosts = new.data.content.posts.filter({ $0.type == selectedScope.rawValue })
                        })
                        .onChange(of: selectedScope, {_, new in
                            selectedPosts = news.data.content.posts.filter({ $0.type == new.rawValue })
                        })
                    }
                }
            } else {
                ContentUnavailableView("news.waiting", systemImage: "arrow.down")
            }
        }
        .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(.black.opacity(0.5)))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .frame(width: 420, height: 310)
        .onAppear {
            fetchNews(type: gameType)
        }
        .onChange(of: gameType, { old, new in
            currentIndex = 0
            fetchNews(type: new)
            timer?.invalidate()
        })
    }
    
    private func openBrowser(website: String) {
        let url = URL(string: website)!
        NSWorkspace.shared.open(url)
    }
    
    private func startTimer(news: LauncherNews) {
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { timer in
            withAnimation(.easeInOut) {
                DispatchQueue.main.async {
                    let page = self.currentIndex + 1
                    if page > news.data.content.banners.count - 1 {
                        self.currentIndex = 0
                    } else {
                        self.currentIndex = page
                    }
                }
            }
        }
    }
    
    private func fetchNews(type: GameKit.GameType) {
        let repo = LauncherNewsRepo(configKey: "launcherNews\(type.rawValue)LastFetchDate", type: type)
        Task.detached {
            do {
                if repo.shouldFetchToday {
                    let news = try await repo.fetchFromNetwork()
                    await MainActor.run {
                        self.news = news
                    }
                } else {
                    let local = repo.fetchFromDisk()
                    await MainActor.run {
                        self.news = local
                    }
                }
            } catch {
                await MainActor.run {
                    svm.sendGlobalMessage(
                        context: String.localizedStringWithFormat(
                            NSLocalizedString("news.error.fetch", comment: ""),
                            error.localizedDescription
                        ),
                        msgType: .Error
                    )
                }
            }
        }
    }
}

extension GameNewsPane {
    struct NewsTypeIndicator: View {
        let title: String
        let showSelected: Bool
        
        var body: some View {
            VStack {
                Text(title).font(.title3).bold().colorScheme(.dark)
                GeometryReader { geo in
                    Rectangle()
                        .fill(.accent.opacity((showSelected) ? 1 : 0))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .frame(width: geo.size.width, height: 2)
                }
            }
            .padding(4)
        }
    }
}

extension GameNewsPane {
    enum NewsType: String {
        case Activity = "POST_TYPE_ACTIVITY"
        case Notice = "POST_TYPE_ANNOUNCE"
        case Info = "POST_TYPE_INFO"
    }
}
