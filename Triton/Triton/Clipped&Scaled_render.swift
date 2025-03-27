//
//  ContentView.swift
//  heatmap_2_rework
//
//  Created by Diego D’Angelo-Cosme on 3/13/25.
//

import SwiftUI

struct DockingView: View {
    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let screenHeight = geometry.size.height
            let boatWidth: CGFloat = 40
            let triangleBaseWidth: CGFloat = screenWidth * 2.25
            let triangleHeight: CGFloat = screenHeight * 0.97
            
            ZStack {
                // Background Grid
                
                // Shaded Docking Area (Blue Triangle)
                TrianglePath(baseWidth: triangleBaseWidth, height: triangleHeight)
                    .fill(Color.blue.opacity(0.5))
                    .overlay(TrianglePath(baseWidth: triangleBaseWidth, height: triangleHeight).stroke(Color.black, lineWidth: 2))
                    .position(x: screenWidth / 2, y: screenHeight * 0.85 - triangleHeight / 2)

                // Obstacles (Green Rectangles)
                ObstacleView(screenWidth: screenWidth, screenHeight: screenHeight)

                // Boat Triangle (White Triangle)
                BoatTriangle()
                    .fill(Color.white)
                    .overlay(BoatTriangle().stroke(Color.black, lineWidth: 2))
                    .frame(width: boatWidth, height: boatWidth)
                    .position(x: screenWidth / 2, y: screenHeight * 0.85)
                
                GridView(rows: 15, columns: 10)
                    .opacity(0.3)
            }
            .edgesIgnoringSafeArea(.all)
        }
    }
}

// MARK: - Triangle Path (Blue Docking Area)
struct TrianglePath: Shape {
    var baseWidth: CGFloat
    var height: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX - baseWidth / 2, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX + baseWidth / 2, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY + height))
        path.closeSubpath()
        return path
    }
}

// MARK: - Boat Triangle (White Triangle)
struct BoatTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}




// MARK: - Obstacle View (Green Rectangles)
/*

struct ObstacleView: View {
    var screenWidth: CGFloat
    var screenHeight: CGFloat
    let obstacleDistances: [CGFloat] = [15, 6.23, 9, 14, 0.5, 2.1, 15, 5, 15, 15] // Example distances in meters

    func scaledHeight(for distance: CGFloat) -> CGFloat {
        let minDistance: CGFloat = 0.5
        let maxDistance: CGFloat = 15
        let minHeight = screenHeight * 0.1 // Just above the triangle
        let maxHeight = screenHeight * 0.8 // Almost full screen
        
        let normalized = (distance - minDistance) / (maxDistance - minDistance)
        return maxHeight - normalized * (maxHeight - minHeight)
    }

    var body: some View {
        let obstacleCount = obstacleDistances.count
        let obstacleWidth = screenWidth / CGFloat(obstacleCount)

        ZStack {
            ForEach(0..<obstacleCount, id: \.self) { index in
                let xPosition = obstacleWidth * CGFloat(index) + obstacleWidth / 2
                let height = scaledHeight(for: obstacleDistances[index])

                Rectangle()
                    .fill(Color.green.opacity(0.7))
                    .frame(width: obstacleWidth, height: height)
                    .position(x: xPosition, y: height / 2)
            }
        }
    }
}

*/
struct ObstacleView: View {
    var screenWidth: CGFloat
    var screenHeight: CGFloat
    let obstacleDistances: [CGFloat] = [15, 15, 5, 0.5, 4.5, 11.5, 0.5, 0.5, 0.5, 0.5] // Example distances in meters

    func scaledHeight(for distance: CGFloat) -> CGFloat {
        let minDistance: CGFloat = 0.5
        let maxDistance: CGFloat = 15
        let minHeight = screenHeight * 0.1 // Just above the triangle
        let maxHeight = screenHeight * 0.8 // Adjusted for better scaling
        
        let normalized = (distance - minDistance) / (maxDistance - minDistance)
        return maxHeight - normalized * (maxHeight - minHeight)
    }

    var body: some View {
        let obstacleCount = obstacleDistances.count
        let obstacleWidth = screenWidth / CGFloat(obstacleCount)

        ZStack {
            ForEach(0..<obstacleCount, id: \.self) { index in
                let xPosition = obstacleWidth * CGFloat(index) + obstacleWidth / 2
                let height = scaledHeight(for: obstacleDistances[index])

                Rectangle()
                    .fill(Color.green.opacity(0.7))
                    .frame(width: obstacleWidth, height: height)
                    .position(x: xPosition, y: height / 2)
            }
        }
        .clipShape(TrianglePath(baseWidth: screenWidth * 2, height: screenHeight * 0.77)) // Clip to triangle
        
    }
}



// MARK: - Grid Background
struct GridView: View {
    var rows: Int
    var columns: Int
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let rowSpacing = height / CGFloat(rows)
            let columnSpacing = width / CGFloat(columns)
            
            Path { path in
                for row in 0...rows {
                    let y = CGFloat(row) * rowSpacing
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: width, y: y))
                }
                for column in 0...columns {
                    let x = CGFloat(column) * columnSpacing
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: height))
                }
            }
            .stroke(Color.gray, lineWidth: 0.5)
        }
    }
}

//// MARK: - Preview
//struct ContentView: View {
//    var body: some View {
//        DockingView()
//    }
//}

struct DockingView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

