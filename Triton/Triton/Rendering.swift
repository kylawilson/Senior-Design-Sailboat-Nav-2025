//
//  Rendering.swift
//  Triton
//
//  Created by Kyla Wilson on 1/30/25.
//

//written by Diego

import SwiftUI

//struct MovingCirclesView: View {
//    let circleCount = 6
//    @State private var positions: [(x: CGFloat, y: CGFloat)] = []
//    
//    var body: some View {
//        GeometryReader { geometry in
//            ZStack {
//                // Triangle at the bottom center
//                Triangle()
//                    .fill(Color.white)
//                    .overlay(Triangle().stroke(Color.black, lineWidth: 3))
//                    .frame(width: 35, height: 35)
//                    .position(x: geometry.size.width / 2, y: geometry.size.height * 0.9)
//                
//                // Moving Circles
//                ForEach(0..<circleCount, id: \.self) { i in
//                    if i < positions.count {
//                        MovingCircle(
//                            delay: Double(i) / 2,
//                            startX: positions[i].x,
//                            startY: positions[i].y,  // Corrected: Use Y instead of X
//                            viewHeight: geometry.size.height
//                        )
//                    }
//                }
//            }
//            .frame(width: 300, height: 400)  // Fixed view size
//            .background(Color.blue)
//            .clipped() // Ensure circles don't move outside the view
//            .onAppear { generateRandomPositions(viewWidth: 300, viewHeight: 400) }
//        }
//        .frame(width: 300, height: 400)  // Fixed external frame to prevent resizing
//    }
//    
//    private func generateRandomPositions(viewWidth: CGFloat, viewHeight: CGFloat) {
//        positions = (0..<circleCount).map { _ in
//            let randomX = CGFloat.random(in: 0.1 * viewWidth ... 0.9 * viewWidth)
//            let randomY = CGFloat.random(in: -150 ... -50) // Start above the view
//            return (x: randomX, y: randomY)
//        }
//    }
//}
//
//// Triangle Shape
//struct Triangle: Shape {
//    func path(in rect: CGRect) -> Path {
//        var path = Path()
//        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
//        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
//        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
//        path.closeSubpath()
//        return path
//    }
//}
//
//// Moving Circle
//struct MovingCircle: View {
//    @State private var offset: CGFloat = 0
//    var delay: Double
//    var startX: CGFloat
//    var startY: CGFloat
//    var viewHeight: CGFloat
//    
//    var body: some View {
//        Circle()
//            .fill(Color.pink)
//            .overlay(Circle().stroke(Color.black, lineWidth: 3))
//            .frame(width: 30, height: 30)
//            .position(x: startX, y: startY)
//            .offset(y: offset)
//            .onAppear {
//                withAnimation(Animation.linear(duration: 2.0).repeatForever(autoreverses: false).delay(delay)) {
//                    offset = viewHeight + 50  // Move down inside the fixed view
//                }
//            }
//    }
//}

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
                // Draw horizontal lines
                for row in 0...rows {
                    let y = CGFloat(row) * rowSpacing
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: width, y: y))
                }
                
                // Draw vertical lines
                for column in 0...columns {
                    let x = CGFloat(column) * columnSpacing
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: height))
                }
            }
            .stroke(Color.black, lineWidth: 0.5) // Thin black lines
        }
    }
}

struct CircleData: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
}

struct MovingCirclesView: View {
    @State private var circles: [CircleData] = []
    @State private var rst: Bool = false
    @State private var num_circles: Int = 3
    @State private var circlePositions: [(CGFloat, CGFloat)] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Triangle
                Triangle()
                    .fill(Color.white)
                    .overlay(Triangle().stroke(Color.black, lineWidth: 3))
                    .frame(width: 35, height: 35)
                    .position(x: geometry.size.width / 2, y: geometry.size.height * 0.9)
                
                // Circles
                ForEach(circles) { circle in
                    Circle()
                        .fill(Color.pink)
                        .overlay(Circle().stroke(Color.black, lineWidth: 3))
                        .frame(width: 30, height: 30)
                        .position(x: circle.x, y: circle.y)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.blue.edgesIgnoringSafeArea(.all))
            .onAppear {
                let screenWidth = geometry.size.width
                let screenHeight = geometry.size.height
                initializePositions(screenWidth: screenWidth, screenHeight: screenHeight)
                addCircles()
            }
        }
        .background(Color.blue.edgesIgnoringSafeArea(.all))
    }
    func initializePositions(screenWidth: CGFloat, screenHeight: CGFloat) {
            circlePositions = [
                (screenWidth * 0.2, screenHeight * 0.3),
                (screenWidth * 0.4, screenHeight * 0.5),
                (screenWidth * 0.6, screenHeight * 0.2),
                (screenWidth * 0.3, screenHeight * 0.7),
                (screenWidth * 0.8, screenHeight * 0.6)
            ] // Example predefined positions

            // If num_circles is greater than the predefined positions, fill with default values
            while circlePositions.count < num_circles {
                circlePositions.append((screenWidth / 2, screenHeight / 2)) // Default to center if missing
            }
        }
    func addCircles() {
        if rst {
            circles.removeAll()
        } else {
            if circlePositions.count < num_circles {
                        print("Warning: circlePositions has only \(circlePositions.count) elements but num_circles is \(num_circles).")
                        return
                    }
            circles = (0..<num_circles).map { i in
                CircleData(x: circlePositions[i].0, y: circlePositions[i].1)
                                            }
                }
    }
}

// Triangle Shape
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
