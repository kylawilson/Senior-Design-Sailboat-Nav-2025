//
//  Rendering.swift
//  Triton
//
//  Created by Kyla Wilson on 1/30/25.
//

//written by Diego

import SwiftUI

struct MovingCirclesView: View {
    let circleCount = 6
    @State private var positions: [(x: CGFloat, y: CGFloat)] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Triangle at the bottom center
                Triangle()
                    .fill(Color.white)
                    .overlay(Triangle().stroke(Color.black, lineWidth: 3))
                    .frame(width: 35, height: 35)
                    .position(x: geometry.size.width / 2, y: geometry.size.height * 0.9)
                
                // Moving Circles
                ForEach(0..<circleCount, id: \.self) { i in
                    if i < positions.count {
                        MovingCircle(
                            delay: Double(i) / 2,
                            startX: positions[i].x,
                            startY: positions[i].y,  // Corrected: Use Y instead of X
                            viewHeight: geometry.size.height
                        )
                    }
                }
            }
            .frame(width: 300, height: 400)  // Fixed view size
            .background(Color.blue)
            .clipped() // Ensure circles don't move outside the view
            .onAppear { generateRandomPositions(viewWidth: 300, viewHeight: 400) }
        }
        .frame(width: 300, height: 400)  // Fixed external frame to prevent resizing
    }
    
    private func generateRandomPositions(viewWidth: CGFloat, viewHeight: CGFloat) {
        positions = (0..<circleCount).map { _ in
            let randomX = CGFloat.random(in: 0.1 * viewWidth ... 0.9 * viewWidth)
            let randomY = CGFloat.random(in: -150 ... -50) // Start above the view
            return (x: randomX, y: randomY)
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

// Moving Circle
struct MovingCircle: View {
    @State private var offset: CGFloat = 0
    var delay: Double
    var startX: CGFloat
    var startY: CGFloat
    var viewHeight: CGFloat
    
    var body: some View {
        Circle()
            .fill(Color.pink)
            .overlay(Circle().stroke(Color.black, lineWidth: 3))
            .frame(width: 30, height: 30)
            .position(x: startX, y: startY)
            .offset(y: offset)
            .onAppear {
                withAnimation(Animation.linear(duration: 2.0).repeatForever(autoreverses: false).delay(delay)) {
                    offset = viewHeight + 50  // Move down inside the fixed view
                }
            }
    }
}
