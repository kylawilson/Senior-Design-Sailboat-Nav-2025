//
//  ContentView.swift
//  Heat_Map_Visual
//
//  Created by Diego D’Angelo-Cosme on 3/8/25.
//
/*
import SwiftUI

struct DockingView: View {
    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let screenHeight = geometry.size.height
            let boatWidth: CGFloat = 40  // Width of the white triangle (boat)
            let triangleBaseWidth: CGFloat = screenWidth  // Base of blue triangle at the top
            let triangleHeight: CGFloat = screenHeight * 0.97  // Height of blue triangle

            ZStack {
                // Background Grid
                GridView(rows: 15, columns: 10)
                    .opacity(0.3)

                // Shaded Docking Area (Blue Triangle)
                TrianglePath(baseWidth: triangleBaseWidth, height: triangleHeight)
                    .fill(Color.blue.opacity(0.5))
                    .overlay(TrianglePath(baseWidth: triangleBaseWidth, height: triangleHeight).stroke(Color.black, lineWidth: 2))
                    .position(x: screenWidth / 2, y: screenHeight * 0.85 - triangleHeight / 2)  // Adjusted to flip

                // Boat Triangle (White Triangle)
                BoatTriangle()
                    .fill(Color.white)
                    .overlay(BoatTriangle().stroke(Color.black, lineWidth: 2))
                    .frame(width: boatWidth, height: boatWidth)
                    .position(x: screenWidth / 2, y: screenHeight * 0.85) // Near bottom center
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

        path.move(to: CGPoint(x: rect.midX - baseWidth / 2, y: rect.minY)) // Left top
        path.addLine(to: CGPoint(x: rect.midX + baseWidth / 2, y: rect.minY)) // Right top
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY + height)) // Bottom center (aligned with boat)
        path.closeSubpath()

        return path
    }
}

// MARK: - Boat Triangle (White Triangle)
struct BoatTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY)) // Top (Vertex)
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY)) // Bottom left
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY)) // Bottom right
        path.closeSubpath()
        return path
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

// MARK: - Preview
struct ContentView: View {
    var body: some View {
        DockingView()
    }
}

struct DockingView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
*/
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/*
import SwiftUI

struct DockingView: View {
    let obstacles: [Obstacle] = [
        Obstacle(width: 20, distance: 8, angle: 0),
        Obstacle(width: 15, distance: 5, angle: -15),
        Obstacle(width: 10, distance: 12, angle: 10)
    ]
    
    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let screenHeight = geometry.size.height
            let boatWidth: CGFloat = 40  // White triangle (boat) width
            let triangleBaseWidth: CGFloat = screenWidth  // Base of blue triangle at the top
            let triangleHeight: CGFloat = screenHeight * 0.97  // Height of blue triangle
            let boatY: CGFloat = screenHeight * 0.85 // Boat position

            ZStack {
                // Background Grid
                GridView(rows: 15, columns: 10)
                    .opacity(0.3)

                // Shaded Docking Area (Blue Triangle)
                TrianglePath(baseWidth: triangleBaseWidth, height: triangleHeight)
                    .fill(Color.blue.opacity(0.5))
                    .overlay(TrianglePath(baseWidth: triangleBaseWidth, height: triangleHeight).stroke(Color.black, lineWidth: 2))
                    .position(x: screenWidth / 2, y: boatY - triangleHeight / 2)

                // Obstacles (Green Boxes)
                ForEach(obstacles) { obstacle in
                    ObstacleView(obstacle: obstacle, screenWidth: screenWidth, screenHeight: screenHeight, triangleHeight: triangleHeight, boatY: boatY)
                }

                // Boat Triangle (White Triangle)
                BoatTriangle()
                    .fill(Color.white)
                    .overlay(BoatTriangle().stroke(Color.black, lineWidth: 2))
                    .frame(width: boatWidth, height: boatWidth)
                    .position(x: screenWidth / 2, y: boatY) // Near bottom center
            }
            .edgesIgnoringSafeArea(.all)
        }
    }
}

// MARK: - Obstacle Model
struct Obstacle: Identifiable {
    let id = UUID()
    var width: CGFloat    // Real-world width in meters
    var distance: CGFloat // Distance from boat in meters
    var angle: CGFloat    // Angle in degrees relative to boat
}

// MARK: - Obstacle View
struct ObstacleView: View {
    var obstacle: Obstacle
    var screenWidth: CGFloat
    var screenHeight: CGFloat
    var triangleHeight: CGFloat
    var boatY: CGFloat
    
    var body: some View {
        let maxDistance: CGFloat = 15  // Max detection range in meters
        let scaleX = screenWidth / 2   // Scale object width based on triangle width
        let scaleY = triangleHeight / maxDistance // Scale distance in Y direction

        let obstacleWidth = (obstacle.width / maxDistance) * scaleX // Scale width
        let obstacleXOffset = tan(obstacle.angle * .pi / 180) * obstacle.distance * scaleX / maxDistance // Angle shift
        let obstacleY = boatY - (obstacle.distance * scaleY) // Move up based on distance
        
        Rectangle()
            .fill(Color.green.opacity(0.8))
            .frame(width: obstacleWidth, height: 20) // Fixed height
            .position(x: (screenWidth / 2) + obstacleXOffset, y: obstacleY)
    }
}

// MARK: - Triangle Path (Blue Docking Area)
struct TrianglePath: Shape {
    var baseWidth: CGFloat
    var height: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX - baseWidth / 2, y: rect.minY)) // Left top
        path.addLine(to: CGPoint(x: rect.midX + baseWidth / 2, y: rect.minY)) // Right top
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY + height)) // Bottom center (aligned with boat)
        path.closeSubpath()
        return path
    }
}

// MARK: - Boat Triangle (White Triangle)
struct BoatTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY)) // Top (Vertex)
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY)) // Bottom left
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY)) // Bottom right
        path.closeSubpath()
        return path
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

// MARK: - Preview
struct ContentView: View {
    var body: some View {
        DockingView()
    }
}

struct DockingView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
*/

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*
import SwiftUI

struct DockingView: View {
    let obstacles: [Obstacle] = [
        Obstacle(width: 20, distance: 8, angle: 0),
        Obstacle(width: 15, distance: 5, angle: -15),
        Obstacle(width: 10, distance: 12, angle: 10)
    ]
    
    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let screenHeight = geometry.size.height
            let boatWidth: CGFloat = 40  // White triangle (boat) width
            let triangleBaseWidth: CGFloat = screenWidth  // Base of blue triangle at the top
            let triangleHeight: CGFloat = screenHeight * 0.97  // Height of blue triangle
            let boatY: CGFloat = screenHeight * 0.85 // Boat position

            ZStack {
                // Background Grid
                GridView(rows: 15, columns: 10)
                    .opacity(0.3)

                // Blue Docking Area (Base)
                TrianglePath(baseWidth: triangleBaseWidth, height: triangleHeight)
                    .fill(Color.blue.opacity(0.5))
                    .overlay(TrianglePath(baseWidth: triangleBaseWidth, height: triangleHeight).stroke(Color.black, lineWidth: 2))
                    .position(x: screenWidth / 2, y: boatY - triangleHeight / 2)

                // Obstacle Heatmap Effect
                ForEach(obstacles) { obstacle in
                    ObstacleHeatmap(obstacle: obstacle, screenWidth: screenWidth, screenHeight: screenHeight, triangleHeight: triangleHeight, boatY: boatY)
                }

                // Boat Triangle (White Triangle)
                BoatTriangle()
                    .fill(Color.white)
                    .overlay(BoatTriangle().stroke(Color.black, lineWidth: 2))
                    .frame(width: boatWidth, height: boatWidth)
                    .position(x: screenWidth / 2, y: boatY) // Near bottom center
            }
            .edgesIgnoringSafeArea(.all)
        }
    }
}

// MARK: - Obstacle Model
struct Obstacle: Identifiable {
    let id = UUID()
    var width: CGFloat    // Real-world width in meters
    var distance: CGFloat // Distance from boat in meters
    var angle: CGFloat    // Angle in degrees relative to boat
}

// MARK: - Heatmap Effect for Obstacles
struct ObstacleHeatmap: View {
    var obstacle: Obstacle
    var screenWidth: CGFloat
    var screenHeight: CGFloat
    var triangleHeight: CGFloat
    var boatY: CGFloat
    
    var body: some View {
        let maxDistance: CGFloat = 15  // Max detection range in meters
        let scaleX = screenWidth / 2   // Scale width based on triangle width
        let scaleY = triangleHeight / maxDistance // Scale distance in Y direction

        let obstacleWidth = (obstacle.width / maxDistance) * scaleX // Scale width
        let obstacleXOffset = tan(obstacle.angle * .pi / 180) * obstacle.distance * scaleX / maxDistance // Angle shift
        let obstacleY = boatY - (obstacle.distance * scaleY) // Move up based on distance
        
        Path { path in
            path.move(to: CGPoint(x: (screenWidth / 2) + obstacleXOffset - obstacleWidth / 2, y: obstacleY)) // Bottom left
            path.addLine(to: CGPoint(x: (screenWidth / 2) + obstacleXOffset + obstacleWidth / 2, y: obstacleY)) // Bottom right
            path.addLine(to: CGPoint(x: screenWidth / 2, y: boatY - triangleHeight)) // Top of the blue triangle
            path.closeSubpath()
        }
        .fill(Color.green.opacity(0.7))
    }
}

// MARK: - Triangle Path (Blue Docking Area)
struct TrianglePath: Shape {
    var baseWidth: CGFloat
    var height: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX - baseWidth / 2, y: rect.minY)) // Left top
        path.addLine(to: CGPoint(x: rect.midX + baseWidth / 2, y: rect.minY)) // Right top
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY + height)) // Bottom center (aligned with boat)
        path.closeSubpath()
        return path
    }
}

// MARK: - Boat Triangle (White Triangle)
struct BoatTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY)) // Top (Vertex)
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY)) // Bottom left
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY)) // Bottom right
        path.closeSubpath()
        return path
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

// MARK: - Preview
struct ContentView: View {
    var body: some View {
        DockingView()
    }
}

struct DockingView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
*/




import SwiftUI

struct DockingView: View {
    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let screenHeight = geometry.size.height
            let boatWidth: CGFloat = 40
            let triangleBaseWidth: CGFloat = screenWidth * 1.5
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

struct ObstacleView: View {
    var screenWidth: CGFloat
    var screenHeight: CGFloat
    let maxDistance: CGFloat = 15  // Sensor max range (15 meters)
    let minDistance: CGFloat = 1
    
    let obstacles: [(width: CGFloat, distance: CGFloat, angle: CGFloat, rotationAngle: CGFloat)] = [
        (width: 120, distance: 1, angle: 0, rotationAngle: 0),
        (width: 80, distance: 15, angle: 45, rotationAngle: 0),
        (width: 60, distance: 8, angle: -60, rotationAngle: 0)
    ]

    var body: some View {
        ForEach(obstacles, id: \.distance) { obstacle in
            let obstacleWidth = obstacle.width//screenWidth
            let obstacleHeight = screenHeight * 0.85 - obstacle.distance

            let normalizedDistance = (obstacle.distance - minDistance) / (maxDistance - minDistance) // Normalize range
            let yPosition = screenHeight * (0.85 - 0.55 * normalizedDistance)
            let xPosition = screenWidth / 2 + tan(obstacle.angle * .pi / 180) * obstacle.distance * 10 // Adjus for angle
            
            
            Rectangle()
                .fill(Color.green.opacity(0.7))
                .frame(width: obstacleWidth, height: yPosition)//obstacleHeight)
                .position(x: xPosition, y: yPosition/2 - 75)//screenHeight * 0.85 - obstacleHeight / 2)//(screenHeight * 0.85))// - obstacle.distance) + obstacleHeight / 2) // **New: Positioned correctly**
                .rotationEffect(.degrees(obstacle.rotationAngle))
        }
        .clipShape(TrianglePath(baseWidth: screenWidth, height: screenHeight * 0.97))
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
//
//struct DockingView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}

