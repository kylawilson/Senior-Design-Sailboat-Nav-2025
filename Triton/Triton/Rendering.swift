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
//    
//    var body: some View {
//        GeometryReader { geometry in
//            ZStack {
//                // Centered Red Triangle
//                Triangle()
//                    .fill(Color.white)
//                    .overlay(Triangle().stroke(Color.black, lineWidth: 3))
//                    .frame(width: 35, height: 35)
//                    //.position(x: geometry.size.width/2, y: geometry.size.height/2) // Adjust based on screen size
//                
//                // Moving Circles
//                ForEach(0..<circleCount, id: \.self) { i in
//                    MovingCircle(delay: Double(i) * 0.4)
//                }
//            }
//            .frame(maxWidth: .infinity, maxHeight: .infinity)
//            .background(Color.blue/*.edgesIgnoringSafeArea(.all)*/)
//        }
//        .padding()
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
//    @State private var offset: CGFloat = -300
//    var delay: Double
//
//    var body: some View {
//        Circle()
//            .fill(Color.pink)
//            .overlay(Circle().stroke(Color.black, lineWidth: 3))
//            .frame(width: 30, height: 30)
//            .offset(x: 0, y: offset)
//            .onAppear {
//                withAnimation(Animation.linear(duration: 4).repeatForever(autoreverses: false).delay(delay)) {
//                    offset = 150
//                }
//            }
//    }
//}

struct MovingCirclesView: View {
    let circleCount = 6
    @State private var positions: [(x: CGFloat, y: CGFloat)] = []
   // @State private var ypositions: [CGFloat] = []
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                //creating the triangle
                Triangle()
                    .fill(Color.white)
                    .overlay(Triangle().stroke(Color.black, lineWidth: 3))
                    .frame(width: 35, height: 35)
                    .position(x: geometry.size.width/2, y: geometry.size.height * 0.9) // Adjust based on screen size
                
                // Moving Circles
                ForEach(0..<circleCount, id: \.self) { i in
                    if i < positions.count{
                        MovingCircle(
                            delay: Double(i)/2,
                            startX: positions[i].x,
                            startY: positions[i].x,
                            screenHeight: geometry.size.height
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.blue.edgesIgnoringSafeArea(.all))
            .onAppear {generateRandomPositions(screenWidth: geometry.size.width, screenHeight: geometry.size.height)}
        }
    }

    private func generateRandomPositions(screenWidth: CGFloat, screenHeight: CGFloat) {
            positions = (0..<circleCount).map { _ in
                let randomX = CGFloat.random(in: 0.5*screenWidth...screenWidth) // Random X within screen width
                let randomY = CGFloat.random(in: -200...screenHeight) // Start above the screen (-200 to -50)
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
    @State private var offset: CGFloat = 0 //was -300
    var delay: Double
    var startX: CGFloat
    var startY: CGFloat
    var screenHeight: CGFloat
    var body: some View {
        Circle()
            .fill(Color.pink)
            .overlay(Circle().stroke(Color.black, lineWidth: 3))
            .frame(width: 30, height: 30)
            .position(x:startX, y:startY)
            .offset(y: offset)
            .onAppear {
                withAnimation(Animation.linear(duration: 1.0).repeatForever(autoreverses: false).delay(delay)) {
                    offset = 150
                }
            }
    }
}
