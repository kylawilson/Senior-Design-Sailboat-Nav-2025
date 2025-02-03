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
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Centered Red Triangle
                Triangle()
                    .fill(Color.white)
                    .overlay(Triangle().stroke(Color.black, lineWidth: 3))
                    .frame(width: 35, height: 35)
                    .position(x: geometry.size.width/2, y: geometry.size.height/2) // Adjust based on screen size
                
                // Moving Circles
                ForEach(0..<circleCount, id: \.self) { i in
                    MovingCircle(delay: Double(i) * 0.4)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.blue.edgesIgnoringSafeArea(.all))
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
    @State private var offset: CGFloat = -300
    var delay: Double

    var body: some View {
        Circle()
            .fill(Color.pink)
            .overlay(Circle().stroke(Color.black, lineWidth: 3))
            .frame(width: 30, height: 30)
            .offset(x: 0, y: offset)
            .onAppear {
                withAnimation(Animation.linear(duration: 4).repeatForever(autoreverses: false).delay(delay)) {
                    offset = 150
                }
            }
    }
}
