import SwiftUI

struct PolarGridView: View {
    let rings = 5
    let lines = 8
    
    //MARK: Use Below for Integration
    
    let rawOAKDDistances: [CGFloat]
    let rawLeftSPDistances: [CGFloat]
    let rawRightSPDistances: [CGFloat]
    //important note: for the StereoPi, even if we only receive 1 value, we still need an array of at least 10
    //of that value to create a solid bar for the depth
    
    
    
    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)
            GeometryReader { geometry in
                let size = min(geometry.size.width, geometry.size.height)
                let center = CGPoint(x: size / 2, y: size / 2)
                let maxRadius = size / 2
                
                let scaledOAKD = rawOAKDDistances.map(scaleDistance)
                let scaledLeft = rawLeftSPDistances.map(scaleDistance)
                let scaledRight = rawRightSPDistances.map(scaleDistance)
                
                ZStack {
                    ConcentricGridView(center: center, maxRadius: maxRadius, rings: rings, lines: lines)

                    OAKDObjectView(distances: scaledOAKD, rawDistances: rawOAKDDistances, center: center, maxRadius: maxRadius)

                    StereoPIZoneView(distances: scaledLeft, rawDistances: rawLeftSPDistances, center: center, maxRadius: maxRadius, startAngle: 225, color: .yellow)

                    StereoPIZoneView(distances: scaledRight, rawDistances: rawRightSPDistances, center: center, maxRadius: maxRadius, startAngle: 45, color: .yellow)

                    BoatTriangleView(center: center)
                }
                .frame(width: size, height: size)
                .position(x: geometry.size.width / 2, y: geometry.size.height * 0.35)
            }
        }
    }
    func scaleDistance(_ value: CGFloat) -> CGFloat {
        let minInput: CGFloat = 0.5
        let maxInput: CGFloat = 15
        let minOutput: CGFloat = 25
        let maxOutput: CGFloat = 200
        return ((value - minInput) / (maxInput - minInput)) * (maxOutput - minOutput) + minOutput
    }
}


struct ConcentricGridView: View {
    let center: CGPoint
    let maxRadius: CGFloat
    let rings: Int
    let lines: Int
    
    var body: some View {
        ZStack {
            ForEach(1...rings, id: \.self) { index in
                Circle()
                    .stroke(Color.blue, lineWidth: 1.5)
                    .frame(width: CGFloat(index) / CGFloat(rings) * maxRadius * 2,
                           height: CGFloat(index) / CGFloat(rings) * maxRadius * 2)
            }
            
            ForEach(0..<lines, id: \.self) { index in
                Path { path in
                    let angle = Angle.degrees(Double(index) / Double(lines) * 360)
                    let endX = center.x + cos(angle.radians) * maxRadius
                    let endY = center.y + sin(angle.radians) * maxRadius
                    path.move(to: center)
                    path.addLine(to: CGPoint(x: endX, y: endY))
                }
                .stroke(Color.blue, lineWidth: 1.5)
            }
        }
    }
}
struct OAKDObjectView: View {
    let distances: [CGFloat]
    let rawDistances: [CGFloat]
    let center: CGPoint
    let maxRadius: CGFloat

    var body: some View {
        let positions = distances.enumerated().map { (index, distance) -> CGPoint in
            let angle = Angle(degrees: 135.0 - (90.0 / Double(distances.count - 1)) * Double(index))
            return CGPoint(
                x: center.x + cos(angle.radians) * distance,
                y: center.y - sin(angle.radians) * distance
            )
        }

        return ZStack {
            ForEach(Array(positions.enumerated()), id: \.element) { index, position in
                let isRed = rawDistances[index] <= 3
                let fillColor = isRed ? Color.red.opacity(0.5) : Color.green.opacity(0.5)
                
                Path { path in
                    let angle = Angle(degrees: 135.0 - (90.0 / Double(distances.count - 1)) * Double(index))
                    let outerX = center.x + cos(angle.radians) * maxRadius
                    let outerY = center.y - sin(angle.radians) * maxRadius

                    path.move(to: CGPoint(x: outerX, y: outerY))
                    path.addLine(to: position)

                    if index < positions.count - 1 {
                        path.addLine(to: positions[index + 1])
                        let nextAngle = Angle(degrees: 135.0 - (90.0 / Double(distances.count - 1)) * Double(index + 1))
                        path.addLine(to: CGPoint(x: center.x + cos(nextAngle.radians) * maxRadius,
                                                 y: center.y - sin(nextAngle.radians) * maxRadius))
                    } else {
                        let finalAngle = Angle(degrees: 45)
                        path.addLine(to: CGPoint(x: center.x + cos(finalAngle.radians) * maxRadius,
                                                 y: center.y - sin(finalAngle.radians) * maxRadius))
                    }

                    path.closeSubpath()
                }
                .fill(fillColor)
            }

            ForEach(Array(positions.enumerated()), id: \.element) { index, position in
                Circle()
                    .fill(rawDistances[index] <= 3 ? Color.red : Color.green)
                    .frame(width: 10, height: 10)
                    .position(position)
            }
        }
    }
}
struct StereoPIZoneView: View {
    let distances: [CGFloat]
    let rawDistances: [CGFloat]
    let center: CGPoint
    let maxRadius: CGFloat
    let startAngle: Double
    let color: Color

    var body: some View {
        let positions = distances.enumerated().map { (index, distance) -> CGPoint in
            let angle = Angle(degrees: startAngle - (90.0 / Double(distances.count - 1)) * Double(index))
            return CGPoint(
                x: center.x + cos(angle.radians) * distance,
                y: center.y - sin(angle.radians) * distance
            )
        }

        return Path { path in
            for (index, position) in positions.enumerated() {
                let angle = Angle(degrees: startAngle - (90.0 / Double(distances.count - 1)) * Double(index))
                let outerX = center.x + cos(angle.radians) * maxRadius
                let outerY = center.y - sin(angle.radians) * maxRadius

                if index == 0 {
                    path.move(to: CGPoint(x: outerX, y: outerY))
                }
                path.addLine(to: position)
            }

            for index in (0..<positions.count).reversed() {
                let angle = Angle(degrees: startAngle - (90.0 / Double(distances.count - 1)) * Double(index))
                let outerX = center.x + cos(angle.radians) * maxRadius
                let outerY = center.y - sin(angle.radians) * maxRadius
                path.addLine(to: CGPoint(x: outerX, y: outerY))
            }

            path.closeSubpath()
        }
        .fill(rawDistances.contains(where: { $0 <= 3 }) ? Color.red.opacity(0.5) : color.opacity(0.5))
    }
}
struct BoatTriangleView: View {
    let center: CGPoint

    var body: some View {
        Path { path in
            let size: CGFloat = 20
            path.move(to: CGPoint(x: center.x, y: center.y - size / 2))
            path.addLine(to: CGPoint(x: center.x - size / 2, y: center.y + size / 2))
            path.addLine(to: CGPoint(x: center.x + size / 2, y: center.y + size / 2))
            path.closeSubpath()
        }
        .fill(Color.white)
        .overlay(
            Path { path in
                let size: CGFloat = 20
                path.move(to: CGPoint(x: center.x, y: center.y - size / 2))
                path.addLine(to: CGPoint(x: center.x - size / 2, y: center.y + size / 2))
                path.addLine(to: CGPoint(x: center.x + size / 2, y: center.y + size / 2))
                path.closeSubpath()
            }
            .stroke(Color.black, lineWidth: 2)
        )
    }
}
