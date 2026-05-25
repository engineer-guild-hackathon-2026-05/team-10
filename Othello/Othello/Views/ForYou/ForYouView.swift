import SwiftUI

struct ForYouView: View {
    @Binding var nowPlayingSong: Song?
    @StateObject private var viewModel = ForYouViewModel()
    @State private var selectedArtist: Artist?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        searchBar
                        sectionHeader
                        artistGrid
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(item: $selectedArtist) { artist in
                MusicFeedView(artist: artist, onSongTap: { song in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        nowPlayingSong = song
                    }
                })
            }
            .preferredColorScheme(.dark)
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.gray)
            TextField("アーティスト、曲、アルバム", text: $viewModel.searchQuery)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }

    private var sectionHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("For You")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            Text("あなた向けのアーティスト")
                .font(.subheadline)
                .foregroundStyle(.gray)
        }
        .padding(.top, 4)
    }

    private var artistGrid: some View {
        let artists = viewModel.filteredArtists
        return VStack(spacing: 12) {
            ForEach(Array(stride(from: 0, to: artists.count, by: 3)), id: \.self) { base in
                VStack(spacing: 12) {
                    if base < artists.count {
                        Button { selectedArtist = artists[base] } label: {
                            ArtistLargeCard(artist: artists[base])
                        }
                        .buttonStyle(.plain)
                    }
                    if base + 1 < artists.count {
                        HStack(spacing: 12) {
                            Button { selectedArtist = artists[base + 1] } label: {
                                ArtistMediumCard(artist: artists[base + 1])
                            }
                            .buttonStyle(.plain)
                            if base + 2 < artists.count {
                                Button { selectedArtist = artists[base + 2] } label: {
                                    ArtistMediumCard(artist: artists[base + 2])
                                }
                                .buttonStyle(.plain)
                            } else {
                                Color.clear
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Artist Large Card

private struct ArtistLargeCard: View {
    let artist: Artist

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(colors: artist.gradientColors, startPoint: .topTrailing, endPoint: .bottomLeading)
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    TagChip(label: "● \(artist.tag)")
                    Spacer()
                    playButton
                }
                .padding(14)
                Spacer()
                VStack(alignment: .leading, spacing: 4) {
                    Text(artist.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    Text(artist.listeningCount)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(14)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var playButton: some View {
        Image(systemName: "play.fill")
            .foregroundStyle(.white)
            .padding(10)
            .background(Color.white.opacity(0.25), in: Circle())
    }
}

// MARK: - Artist Medium Card

private struct ArtistMediumCard: View {
    let artist: Artist

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(colors: artist.gradientColors, startPoint: .topTrailing, endPoint: .bottomLeading)
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    TagChip(label: "● \(artist.tag)")
                    Spacer()
                    playButton
                }
                .padding(10)
                Spacer()
                VStack(alignment: .leading, spacing: 2) {
                    Text(artist.name)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    Text(artist.listeningCount)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(10)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 170)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var playButton: some View {
        Image(systemName: "play.fill")
            .foregroundStyle(.white)
            .font(.caption)
            .padding(8)
            .background(Color.white.opacity(0.25), in: Circle())
    }
}

// MARK: - Tag Chip

private struct TagChip: View {
    let label: String
    var body: some View {
        Text(label)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.black.opacity(0.3), in: Capsule())
    }
}

#Preview {
    ForYouView(nowPlayingSong: .constant(nil))
}
