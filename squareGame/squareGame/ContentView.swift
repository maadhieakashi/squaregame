import SwiftUI

// Tile struct with shape and color
struct Tile: Identifiable {
    let id = UUID()
    var color: Color
    var shape: ShapeType
    var isRevealed: Bool = false
    var isMatched: Bool = false
    
    enum ShapeType: CaseIterable, Codable {
        case circle, square, triangle, diamond
        
        @ViewBuilder
        func shapeView(color: Color) -> some View {
            switch self {
            case .circle:
                Circle().fill(color)
            case .square:
                Rectangle().fill(color)
            case .triangle:
                Triangle().fill(color)
            case .diamond:
                Diamond().fill(color)
            }
        }
    }
}

// High Score Entry for saving scores
struct HighScoreEntry: Identifiable, Codable {
    let id = UUID()
    let username: String
    let score: Int
}

// Custom Triangle shape
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.midX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            p.closeSubpath()
        }
    }
}

// Custom Diamond shape
struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.midX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
            p.closeSubpath()
        }
    }
}

struct ContentView: View {
    enum GameLevel: String, CaseIterable {
        case beginner, intermediate, difficult
        
        var gridSize: (rows: Int, columns: Int) {
            switch self {
            case .beginner: return (4, 4)
            case .intermediate: return (4, 5)
            case .difficult: return (5, 6)
            }
        }
    }
    
    @State private var username: String = ""
    @State private var showUsernamePrompt: Bool = true
    @State private var currentLevelIndex: Int = 0
    @State private var currentRound: Int = 1
    @State private var tiles: [Tile] = []
    @State private var firstSelectedIndex: Int? = nil
    @State private var secondSelectedIndex: Int? = nil
    
    @State private var score: Int = 0
    @State private var timeLeft: Int = 60
    @State private var accumulatedTime: Int = 0
    @State private var timer: Timer?
    @State private var gameOver: Bool = false
    @State private var gameCompleted: Bool = false
    @State private var highScores: [HighScoreEntry] = []
    @State private var showGuide: Bool = false
    @State private var animateBackground = false
    
    var currentLevel: GameLevel {
        GameLevel.allCases[currentLevelIndex]
    }
    
    var rows: Int { currentLevel.gridSize.rows }
    var columns: Int { currentLevel.gridSize.columns }
    
    var body: some View {
        ZStack {
            AngularGradient(gradient: Gradient(colors: [Color.indigo, Color.purple, Color.indigo, Color.purple]),
                            center: .center)
                .rotationEffect(.degrees(animateBackground ? 360 : 360))
                .ignoresSafeArea()
                .onAppear {
                    withAnimation(.linear(duration: 60).repeatForever(autoreverses: false)) {
                        animateBackground.toggle()
                    }
                }
            
            VStack(spacing: 20) {
                if showUsernamePrompt {
                    VStack(spacing: 16) {
                        Text("ENTER USERNAME")
                            .font(.title2.bold().monospaced())
                            .foregroundColor(.white)
                        
                        TextField("Username", text: $username)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                            .font(.body.monospaced())
                        
                        Button("Start Game") {
                            if !username.trimmingCharacters(in: .whitespaces).isEmpty {
                                showUsernamePrompt = false
                                resetState()
                                startLevel()
                            }
                        }
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.black.opacity(0.5))
                        .foregroundColor(.white)
                        .cornerRadius(14)
                        .shadow(radius: 6)
                    }
                    .padding()
                } else {
                    VStack(spacing: 16) {
                        Text("🎮 Color & Shape Match Game")
                            .font(.largeTitle.weight(.heavy))
                            .foregroundColor(.white)
                        
                        Text("👤 \(username) | \(currentLevel.rawValue.capitalized) - Round \(currentRound)/3")
                            .font(.headline.monospaced())
                            .foregroundColor(.white.opacity(0.9))
                        
                        HStack(spacing: 30) {
                            Text("⏳ \(timeLeft)s")
                            Text("🏆 \(score)")
                        }
                        .font(.subheadline.monospaced())
                        .foregroundColor(.white)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: columns), spacing: 10) {
                            ForEach(tiles.indices, id: \.self) { index in
                                ZStack {
                                    if tiles[index].isMatched {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.clear)
                                            .frame(height: 60)
                                    } else {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(tiles[index].isRevealed ? Color.white.opacity(0.15) : Color.white.opacity(0.3))
                                            .frame(height: 60)
                                            .shadow(radius: 5)
                                            .overlay {
                                                if tiles[index].isRevealed {
                                                    tiles[index].shape.shapeView(color: tiles[index].color)
                                                        .frame(width: 40, height: 40)
                                                }
                                            }
                                            .onTapGesture {
                                                handleTap(on: index)
                                            }
                                    }
                                }
                                .transition(.scale)
                            }
                        }
                        
                        if gameOver {
                            VStack {
                                Text("💥 Game Over!")
                                    .font(.title)
                                    .foregroundColor(.red)
                                Text("Final Score: \(score)")
                                    .foregroundColor(.white)
                            }
                            .padding()
                        }
                        
                        if gameCompleted {
                            VStack {
                                Text("🎉 Game Completed!")
                                    .font(.title2)
                                    .foregroundColor(.green)
                                Text("🏁 Final Score: \(score)")
                                    .foregroundColor(.white)
                            }
                            .padding()
                        }
                        
                        HStack(spacing: 20) {
                            gameButton("🔁 Restart", color: .blue) {
                                stopTimer()
                                resetState()
                                showUsernamePrompt = true
                            }
                            gameButton("ℹ️ Guide", color: .purple) {
                                showGuide = true
                            }
                            gameButton("📊 High Scores", color: .orange) {
                                loadHighScores()
                                gameOver = true
                            }
                        }
                        .padding(.top)
                    }
                    .padding()
                }
                
                if !highScores.isEmpty {
                    VStack(alignment: .leading) {
                        Text("HIGH SCORES")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        ForEach(highScores.sorted(by: { $0.score > $1.score }).prefix(5)) { entry in
                            Text("• \(entry.username): \(entry.score)")
                                .font(.body.monospaced())
                                .foregroundColor(.white.opacity(0.85))
                        }
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showGuide) {
            GuideView()
        }
        .onAppear {
            resetState()
            loadHighScores()
        }
    }
    
    func resetState() {
        score = 0
        timeLeft = 60
        accumulatedTime = 0
        gameOver = false
        gameCompleted = false
        currentLevelIndex = 0
        currentRound = 1
        firstSelectedIndex = nil
        secondSelectedIndex = nil
        tiles = []
    }
    
    func createBoard() {
        let totalTiles = rows * columns
        let pairCount = totalTiles / 2
        
        // Colors and shapes pool
        let baseColors: [Color] = [.red, .blue, .green, .yellow, .purple, .orange, .pink, .mint, .cyan, .indigo]
        let baseShapes = Tile.ShapeType.allCases
        
        // Pick pairs of (color, shape) unique combos
        var pairs: [(Color, Tile.ShapeType)] = []
        
        var attempts = 0
        while pairs.count < pairCount && attempts < 1000 {
            let color = baseColors.randomElement()!
            let shape = baseShapes.randomElement()!
            let pair = (color, shape)
            if !pairs.contains(where: { $0.0 == pair.0 && $0.1 == pair.1 }) {
                pairs.append(pair)
            }
            attempts += 1
        }
        
        // Duplicate pairs and shuffle
        var allPairs = pairs + pairs
        allPairs.shuffle()
        
        // Create tiles
        tiles = allPairs.map { Tile(color: $0.0, shape: $0.1) }
    }
    
    func startLevel() {
        gameOver = false
        gameCompleted = false
        firstSelectedIndex = nil
        secondSelectedIndex = nil
        
        timeLeft = 60 + accumulatedTime
        accumulatedTime = 0
        
        stopTimer()
        createBoard()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            timeLeft -= 1
            if timeLeft <= 0 {
                stopTimer()
                gameOver = true
                saveHighScore()
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
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                checkMatch()
            }
        }
    }
    
    func checkMatch() {
        guard let first = firstSelectedIndex, let second = secondSelectedIndex else { return }
        
        let tile1 = tiles[first]
        let tile2 = tiles[second]
        
        if tile1.color == tile2.color && tile1.shape == tile2.shape {
            tiles[first].isMatched = true
            tiles[second].isMatched = true
            score += 10
        } else {
            tiles[first].isRevealed = false
            tiles[second].isRevealed = false
            score = max(0, score - 2)
        }
        
        firstSelectedIndex = nil
        secondSelectedIndex = nil
        
        if tiles.allSatisfy({ $0.isMatched }) {
            stopTimer()
            accumulatedTime += timeLeft
            if currentRound < 3 {
                currentRound += 1
                startLevel()
            } else if currentLevelIndex < GameLevel.allCases.count - 1 {
                currentLevelIndex += 1
                currentRound = 1
                startLevel()
            } else {
                gameCompleted = true
                saveHighScore()
            }
        }
    }
    
    func saveHighScore() {
        guard score > 0 else { return }
        
        let newEntry = HighScoreEntry(username: username, score: score)
        var stored = loadStoredHighScores()
        
        if let existingIndex = stored.firstIndex(where: { $0.username == username }) {
            if score > stored[existingIndex].score {
                stored[existingIndex] = newEntry
            }
        } else {
            stored.append(newEntry)
        }
        
        if let encoded = try? JSONEncoder().encode(stored) {
            UserDefaults.standard.set(encoded, forKey: "HighScores")
        }
        
        loadHighScores()
    }
    
    func loadStoredHighScores() -> [HighScoreEntry] {
        if let data = UserDefaults.standard.data(forKey: "HighScores"),
           let decoded = try? JSONDecoder().decode([HighScoreEntry].self, from: data) {
            return decoded
        }
        return []
    }
    
    func loadHighScores() {
        let allScores = loadStoredHighScores()
        var filteredDict: [String: HighScoreEntry] = [:]
        
        for entry in allScores where entry.score > 0 {
            if let existing = filteredDict[entry.username] {
                if entry.score > existing.score {
                    filteredDict[entry.username] = entry
                }
            } else {
                filteredDict[entry.username] = entry
            }
        }
        
        highScores = Array(filteredDict.values)
    }
    
    @ViewBuilder
    func gameButton(_ label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.headline.monospaced())
                .frame(maxWidth: .infinity)
                .padding()
                .background(color.opacity(0.85))
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(radius: 4)
        }
    }
}

// MARK: Guide View

struct GuideView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("🎯 How to Play")
                        .font(.largeTitle.bold())
                        .padding(.bottom, 12)
                    
                    Text("""
                    Welcome to the Color & Shape Match Game!

                    • Match tiles based on **both color and shape**.
                    • Tap two tiles to reveal them.
                    • If they match, they stay revealed and you earn points.
                    • If they don’t match, they flip back and you lose points.
                    • Complete 3 rounds in each level: Beginner, Intermediate, Difficult.
                    • Beat the timer and maximize your score!

                    Good luck and have fun!
                    """)
                        .font(.body)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Game Guide")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        // Dismiss the sheet
                        // This uses the environment dismiss to close sheet
                        // Make sure to import SwiftUI
                        dismiss()
                    }
                }
            }
        }
    }
    
    @Environment(\.dismiss) private var dismiss
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
