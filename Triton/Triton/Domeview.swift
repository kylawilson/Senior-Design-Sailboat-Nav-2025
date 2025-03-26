//
//  ContentView.swift
//  Dome-Rendering
//
//  Created by Diego D’Angelo-Cosme on 3/18/25.
//

//THIS IS A GOOD ONE, NEED TO FIX BLUE COLORING AND ALIGN OBSTACLES TO APPEAR ALONG THE CURVE

import SwiftUI

struct DockingView: View {
    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let screenHeight = geometry.size.height
            let boatWidth: CGFloat = 40
            let triangleBaseWidth: CGFloat = screenWidth * 4
            let triangleHeight: CGFloat = screenHeight * 0.85 // Extend to near top
            let domeRadius: CGFloat = triangleBaseWidth / 2 // Align with triangle top
            
            ZStack {
                // Background Grid
                ZStack {
                        // Dome on top of the triangle (aligned with triangle edges)
                        DomeShape(radius: domeRadius)
                            .fill(Color.blue.opacity(0.5))
                            .overlay(DomeShape(radius: domeRadius).stroke(Color.black, lineWidth: 2))
                            .frame(width: domeRadius * 2, height: domeRadius)
                            .position(x: screenWidth / 2, y: domeRadius / 2 + 75)
                        
                        // Shaded Docking Area (Blue Triangle)
                        TrianglePath(baseWidth: triangleBaseWidth, height: triangleHeight)
                            .fill(Color.blue.opacity(0.5))
                            .overlay(TrianglePath(baseWidth: triangleBaseWidth, height: triangleHeight).stroke(Color.black, lineWidth: 2))
                            .position(x: screenWidth / 2, y: screenHeight - triangleHeight / 2 - 50)
                    }
                    .clipShape(TrianglePath(baseWidth: triangleBaseWidth, height: triangleHeight))
            /*    // Dome on top of the triangle (aligned with triangle edges)
                DomeShape(radius: domeRadius)
                    .fill(Color.blue.opacity(0.5))
                    .overlay(DomeShape(radius: domeRadius).stroke(Color.black, lineWidth: 2))
                    .frame(width: domeRadius * 2, height: domeRadius)
                    .position(x: screenWidth / 2, y: domeRadius / 2)
                
                // Shaded Docking Area (Blue Triangle extending to near the top)
                TrianglePath(baseWidth: triangleBaseWidth, height: triangleHeight)
                    .fill(Color.blue.opacity(0.5))
                    .overlay(TrianglePath(baseWidth: triangleBaseWidth, height: triangleHeight).stroke(Color.black, lineWidth: 2))
                    .position(x: screenWidth / 2, y: screenHeight - triangleHeight / 2)
                */
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
struct ObstacleView: View {
    var screenWidth: CGFloat
    var screenHeight: CGFloat
    let obstacleHeights: [CGFloat] = [400, 550, 220, 160, 240, 0.210, 190, 0.230, 0.170, 0.250] // Heights array

    var body: some View {
        let obstacleCount = obstacleHeights.count
        let obstacleWidth = screenWidth / CGFloat(obstacleCount) // Equal width for each obstacle
        
        ZStack {
            ForEach(0..<obstacleCount, id: \ .self) { index in
                let xPosition = obstacleWidth * CGFloat(index) + obstacleWidth / 2
                let yPosition = obstacleHeights[index] / 2 // Start from the top and extend downward

                Rectangle()
                    .fill(Color.green.opacity(0.7))
                    .frame(width: obstacleWidth, height: obstacleHeights[index])
                    .position(x: xPosition, y: yPosition)
            }
        }
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

