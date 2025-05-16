//
//  ContentView.swift
//  ColorMatchGame
//
//  Created by SAHimeshi 002 on 2025-05-04.
//
import SwiftUI

struct Tile: Identifiable {
    let id = UUID()
    var color: Color
    var isRevealed: Bool = false
    var isMatched: Bool = false
}

struct ContentView: View {
    @State private var tiles: [Tile] = []
    @State private var firstSelectedIndex: Int? = nil
    @State private var secondSelectedIndex: Int? = nil

    @State private var score: Int = 0
    @State private var timeLeft: Int = 60
    @State private var timer: Timer?
    @State private var currentLevel: Int = 1
    @State private var maxLevel: Int = 3

    @State private var rows: Int = 4
    @State private var columns: Int = 4

    @State private var gameOver: Bool = false
    @State private var gameCompleted: Bool = false

    var body: some View {
        VStack(spacing: 16) {
            Text(" Color Match Game")
                            .font(.largeTitle)
                            .bold()
            Text("🎮 Level \(currentLevel) / \(maxLevel)")
                .font(.title)
                .bold()

            HStack(spacing: 40) {
                Text("⏳ Time: \(timeLeft)s")
                Text("🏆 Score: \(score)")
            }
            .font(.title3)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: columns), spacing: 10) {
                ForEach(tiles.indices, id: \.self) { index in
                    ZStack {
                        if tiles[index].isMatched {
                            Rectangle()
                                .fill(Color.clear)
                                .frame(height: 70)
                        } else {
                            Rectangle()
                                .fill(tiles[index].isRevealed ? tiles[index].color : Color.gray)
                                .frame(height: 70)
                                .cornerRadius(8)
                                .onTapGesture {
                                    handleTap(on: index)
                                }
                        }
                    }
                }
            }

            if gameOver {
                Text("⛔ Time's Up! Moving to next level...")
                    .foregroundColor(.orange)
            }

            if gameCompleted {
                Text("🎉 Game Completed!\n🏁 Final Score: \(score)")
                    .multilineTextAlignment(.center)
                    .font(.title2)
                    .foregroundColor(.green)
            }

            Button("🟢 Start Game") {
                resetToLevel(level: 1)
            }
            .padding(.top)

            Button("🔁 Restart Game") {
                stopTimer()
                resetState()
                createBoard(rows: rows, columns: columns)
            }
        }
        .padding()
        .onAppear {
            createBoard(rows: rows, columns: columns)
        }
    }

    func resetState() {
        score = 0
        timeLeft = 60
        gameOver = false
        gameCompleted = false
        currentLevel = 1
        firstSelectedIndex = nil
        secondSelectedIndex = nil
    }

    func createBoard(rows: Int, columns: Int) {
        let totalTiles = rows * columns
        let pairCount = totalTiles / 2
        let baseColors: [Color] = [.red, .blue, .green, .yellow, .purple, .orange, .pink, .mint, .cyan, .indigo, .teal, .brown]
        let selectedColors = Array(baseColors.shuffled().prefix(pairCount))
        let allColors = (selectedColors + selectedColors).shuffled()
        tiles = allColors.map { Tile(color: $0) }
    }

    func startLevel() {
        gameOver = false
        gameCompleted = false
        firstSelectedIndex = nil
        secondSelectedIndex = nil
        timeLeft = 60

        stopTimer()
        createBoard(rows: rows, columns: columns)

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            timeLeft -= 1
            if timeLeft <= 0 {
                stopTimer()
                gameOver = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    advanceLevel()
                }
            }
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    func handleTap(on index: Int) {
        guard !gameOver, !gameCompleted else { return }
        guard !tiles[index].isMatched, !tiles[index].isRevealed, secondSelectedIndex == nil else { return }

        if firstSelectedIndex == nil {
            firstSelectedIndex = index
            tiles[index].isRevealed = true
        } else if secondSelectedIndex == nil && index != firstSelectedIndex {
            secondSelectedIndex = index
            tiles[index].isRevealed = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                checkMatch()
            }
        }
    }

    func checkMatch() {
        guard let first = firstSelectedIndex, let second = secondSelectedIndex else { return }

        if tiles[first].color == tiles[second].color {
            tiles[first].isMatched = true
            tiles[second].isMatched = true
            score += 10
        } else {
            tiles[first].isRevealed = false
            tiles[second].isRevealed = false
            score -= 2
        }

        firstSelectedIndex = nil
        secondSelectedIndex = nil

        if tiles.allSatisfy({ $0.isMatched }) {
            stopTimer()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                advanceLevel()
            }
        }
    }

    func advanceLevel() {
        if currentLevel < maxLevel {
            currentLevel += 1
            columns += 1
            startLevel()
        } else {
            gameCompleted = true
            gameOver = false
        }
    }

    func resetToLevel(level: Int) {
        currentLevel = level
        columns = 3 + level // 4x4, 4x5, 4x6
        rows = 4
        score = 0
        startLevel()
    }
}

#Preview {
    ContentView()
}


