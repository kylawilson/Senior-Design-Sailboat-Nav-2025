//
//  ContentView.swift
//  Dome-Rendering
//
//  Created by Diego D’Angelo-Cosme on 3/18/25.
//
/*
import SwiftUI

struct DockingView: View {
    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let screenHeight = geometry.size.height
            let boatWidth: CGFloat = 40
            let triangleBaseWidth: CGFloat = screenWidth * 2.5 //was 2.5
            let triangleHeight: CGFloat = screenHeight * 0.85 // was 0.85, Extend to near top
            let domeRadius: CGFloat = triangleBaseWidth / 2 // Align with triangle top
            
            ZStack {
                // Background Grid
                ZStack {
                    TrianglePath(baseWidth: triangleBaseWidth, height: triangleHeight)
                        .fill(Color.black.opacity(0.1))
                        .overlay(TrianglePath(baseWidth: triangleBaseWidth, height: triangleHeight).stroke(Color.black, lineWidth: 2))
                        .position(x: screenWidth / 2, y: screenHeight - triangleHeight / 2 - 50)
                        // Dome on top of the triangle (aligned with triangle edges)
                        DomeShape(radius: domeRadius)
                            .fill(Color.blue.opacity(0.5))
                            .overlay(DomeShape(radius: domeRadius).stroke(Color.black, lineWidth: 2))
                            .frame(width: domeRadius * 2, height: domeRadius)
                            .position(x: screenWidth / 2, y: domeRadius / 2 + 75)
                        
                        // Shaded Docking Area (Blue Triangle)
                        
                    }
                    .clipShape(TrianglePath(baseWidth: triangleBaseWidth, height: triangleHeight))
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
 
/*
struct DockingView: View {
    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let screenHeight = geometry.size.height
            let boatWidth: CGFloat = 40
            let triangleBaseWidth: CGFloat = screenWidth * 2.5
            let triangleHeight: CGFloat = screenHeight * 0.85 // Extend to near top
            let domeRadius: CGFloat = triangleBaseWidth / 2 // Align with triangle top
            let domeCenterY: CGFloat = triangleHeight - domeRadius / 2 + 75 // Adjust dome position
            
            ZStack {
                // Shaded Docking Area (Blue Triangle) - First Layer
                TrianglePath(baseWidth: triangleBaseWidth, height: triangleHeight)
                    .fill(Color.blue.opacity(0.5))
                    .overlay(TrianglePath(baseWidth: triangleBaseWidth, height: triangleHeight).stroke(Color.black, lineWidth: 2))
                    .position(x: screenWidth / 2, y: screenHeight - triangleHeight / 2 - 50)
                
                // Dome on top of the triangle (aligned correctly)
                DomeShape(radius: domeRadius)
                    .fill(Color.blue.opacity(0.5))
                    .overlay(DomeShape(radius: domeRadius).stroke(Color.black, lineWidth: 2))
                    .frame(width: domeRadius * 2, height: domeRadius)
                    .position(x: screenWidth / 2, y: domeCenterY)
                    .clipped()

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
*/

// MARK: - Dome Shape
struct DomeShape: Shape {
    var radius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(center: CGPoint(x: rect.midX, y: rect.maxY), radius: radius, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        return path
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
    let obstacleDistances: [CGFloat] = [1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5] // Example distances in meters

    func scaledHeight(for distance: CGFloat) -> CGFloat {
        let minDistance: CGFloat = 0.5
        let maxDistance: CGFloat = 15
        let minHeight = screenHeight * 0.1 // Minimum height
        let maxHeight = screenHeight * 0.8 // Maximum height

        let normalized = (distance - minDistance) / (maxDistance - minDistance)
        return maxHeight - normalized * (maxHeight - minHeight) - 50
    }

    var body: some View {
        let obstacleCount = obstacleDistances.count
        let obstacleWidth = screenWidth / CGFloat(obstacleCount)
        let domeRadius = screenWidth * 1.25 // Same as dome
        let domeCenterY = domeRadius + 75 // Y-position of the center of the dome

        ZStack {
            ForEach(0..<obstacleCount, id: \.self) { index in
                let xPosition = obstacleWidth * CGFloat(index) + obstacleWidth / 2
                let height = scaledHeight(for: obstacleDistances[index])

                // Compute arc adjustment
                let xOffset = xPosition - (screenWidth / 2)
                let arcHeightAdjustment = domeCenterY - sqrt(max(domeRadius * domeRadius - xOffset * xOffset, 0))

                let yPosition = arcHeightAdjustment + height / 2 // Adjusted top position

                Rectangle()
                    .fill(Color.yellow.opacity(0.7))
                    .frame(width: obstacleWidth, height: height)
                    .position(x: xPosition, y: yPosition)
            }
        }
        .clipShape(TrianglePath(baseWidth: screenWidth * 2, height: screenHeight*0.86)) // Clip to triangle
    }
}

 */

struct ObstacleView: View {
    var screenWidth: CGFloat
    var screenHeight: CGFloat
    //let obstacleDistances: [CGFloat] = [15, 15, 15, 15, 15, 15, 15, 15, 15, 15] // Example distances in meters
    //let obstacleDistances: [CGFloat] = [1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5, 1.5]
    let obstacleDistances: [CGFloat] = [7, 7, 7, 2, 2, 7, 15, 15, 15, 15]
    func scaledHeight(for distance: CGFloat) -> CGFloat {
        let minDistance: CGFloat = 0.5
        let maxDistance: CGFloat = 15
        let minHeight = screenHeight * 0.1 // Minimum height
        let maxHeight = screenHeight * 0.8 // Maximum height

        let normalized = (distance - minDistance) / (maxDistance - minDistance)
        return maxHeight - normalized * (maxHeight - minHeight) - 50
    }

    func color(for distance: CGFloat) -> Color {
        if distance > 4 {
            return Color.green.opacity(0.7)
        }  else {
            return Color.red.opacity(0.7)
        }
    }

    var body: some View {
        let obstacleCount = obstacleDistances.count
        let obstacleWidth = screenWidth / CGFloat(obstacleCount)
        let domeRadius = screenWidth * 1.25 // Same as dome
        let domeCenterY = domeRadius + 75 // Y-position of the center of the dome

        ZStack {
            ForEach(0..<obstacleCount, id: \.self) { index in
                let xPosition = obstacleWidth * CGFloat(index) + obstacleWidth / 2
                let height = scaledHeight(for: obstacleDistances[index])

                // Compute arc adjustment
                let xOffset = xPosition - (screenWidth / 2)
                let arcHeightAdjustment = domeCenterY - sqrt(max(domeRadius * domeRadius - xOffset * xOffset, 0))

                let yPosition = arcHeightAdjustment + height / 2 // Adjusted top position
                
                Rectangle()
                    .fill(color(for: obstacleDistances[index])) // Dynamic color based on distance
                    .frame(width: obstacleWidth, height: height)
                    .position(x: xPosition, y: yPosition)
                 
                /*
                Circle()
                    .fill(color(for: obstacleDistances[index])) // Dynamic color
                    .frame(width: 15, height: 15) // Adjust size as needed
                    .position(x: xPosition, y: yPosition)
                 */
            }
        }
        .clipShape(TrianglePath(baseWidth: screenWidth * 2, height: screenHeight * 0.86)) // Clip to triangle
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
