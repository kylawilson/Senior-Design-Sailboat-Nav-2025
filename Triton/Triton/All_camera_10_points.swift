//
//  ContentView.swift
//  phone_test
//
//  Created by Diego D’Angelo-Cosme on 4/7/25.
//
//
//  ContentView.swift
//  phone_polar_map
//
//  Created by Diego D’Angelo-Cosme on 3/31/25.
//

//updated variables there may be bugs based on messing things up

import SwiftUI

struct PolarGridView: View {
    let rings = 5
    let lines = 8
    
    
    //let rawOAKDDistances: [CGFloat] = [15, 15, 15, 15, 15, 15, 15, 15, 15, 15] // Example values in range [0.5, 15]
    //let rawOAKDDistances: [CGFloat] = [7.75, 7.75, 7.75, 27, 27.75, 37.75, 7.75, 7.75, 7.75, 7.75]
    //let rawOAKDDistances: [CGFloat] = [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5]
    //let rawLeftSPDistances: [CGFloat] = [8, 8, 8, 8, 8, 8, 8, 8, 8, 8] // Example values for yellow objects
    //let rawRightSPDistances: [CGFloat] = [10, 10, 10, 10, 10, 10, 10, 10, 10, 10] // Example values for yellow objects
    //let rawOAKDDistances: [CGFloat] = [0.5, 2, 3.75, 5.6, 7, 10, 13, 14, 15, 15] // Example values in range [0.5, 15]
    //let rawOAKDDistances: [CGFloat] = [14, 14, 14, 14, 14, 14, 14, 14, 14, 14]
    //let rawLeftSPDistances: [CGFloat] = [0.5, 2, 3.75, 5.6, 7, 10, 13, 14, 15, 15]
    //let rawRightSPDistances: [CGFloat] = [0.5, 2, 3.75, 5.6, 7, 10, 13, 14, 15, 15]
    //let rawLeftSPDistances: [CGFloat] = [14, 14, 14, 14, 14, 14, 14, 14, 14, 14]
   // let rawRightSPDistances: [CGFloat] = [13, 13, 13, 13, 13, 13, 13, 13, 13, 13]
    //let rawLeftSPDistances: [CGFloat] = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
    //let rawRightSPDistances: [CGFloat] = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
    
    //let rawLeftSPDistances: [CGFloat] = [9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9]
    
    //let otherboats: [(CGFloat, CGFloat)] = [(0.5, -45), (10, 0), (3, 32), (25, 25)]
    
    //MARK: Use Below for Integration
    
    let btService: BluetoothService
    let rawOAKDDistances: [CGFloat]
    let rawLeftSPDistances: [CGFloat]
    let rawRightSPDistances: [CGFloat]
    let otherboats: [(CGFloat, CGFloat)]
    
    
    
    var body: some View {
        VStack {
            ZStack {
                Color.white.edgesIgnoringSafeArea(.all)
                GeometryReader { geometry in
                    let size = min(geometry.size.width, geometry.size.height)
                    let center = CGPoint(x: size / 2, y: size / 2)
                    let maxRadius = size / 2
                    
                    let scaledOAKD = rawOAKDDistances.map(preprocessDistance).map(scaleDistance)
                    let scaledLeft = rawLeftSPDistances.map(preprocessDistance).map(scaleDistance)
                    let scaledRight = rawRightSPDistances.map(preprocessDistance).map(scaleDistance)
                    //let scaledOtherboats = otherboats.map { (distance, angle) in
                     //   (processedScaleDistance(distance), angle)
                    //}
                    //if anything goes wrong uncomment these lines above
                    let tooclose = 1.0
                    
                    ZStack {
                        ConcentricGridView(center: center, maxRadius: maxRadius, rings: rings, lines: lines)
                        
                        OAKDObjectView(distances: scaledOAKD, rawDistances: rawOAKDDistances, center: center, maxRadius: maxRadius, tooclose:tooclose)
                        
                        StereoPIZoneView(distances: scaledLeft, rawDistances: rawLeftSPDistances, center: center, maxRadius: maxRadius, startAngle: 225, finalAngle:135, tooclose:tooclose)
                        
                        StereoPIZoneView(distances: scaledRight, rawDistances: rawRightSPDistances, center: center, maxRadius: maxRadius, startAngle: 45, finalAngle: 315, tooclose:tooclose)
                        
                        BoatTriangleView(center: center)
                        
                        OtherBoatsView(boats: otherboats, center: center, scaleDistance: processedScaleDistance)
                    }
                    .frame(width: size, height: size)
                    .position(x: geometry.size.width / 2, y: geometry.size.height * 0.35)
                }
                
            }
            
            TileView(label: "Wind Speed", value: btService.anemometerData.windSpeed)
            TileView(label: "Wind Direction", value: btService.anemometerData.windDirection)
            TileView(label: "COG", value: btService.gpsData.COG)
            TileView(label: "Speed", value: btService.gpsData.speed)
             
        }
    }
    func scaleDistance(_ value: CGFloat) -> CGFloat {
        let minInput: CGFloat = 0.5
        let maxInput: CGFloat = 7
        let minOutput: CGFloat = 25
        let maxOutput: CGFloat = 200
        return ((value - minInput) / (maxInput - minInput)) * (maxOutput - minOutput) + minOutput
    }
    
    
    func preprocessDistance(_ value: CGFloat) -> CGFloat {
        if value >= 7 {
            return 7
        }
        return value
    }
    
    var processedScaleDistance: (CGFloat) -> CGFloat {
        return { value in
            let floored = (value >= 7) ? 7 : value
            return scaleDistance(floored)
        }
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
    let tooclose: CGFloat

    var body: some View {
        let positions = distances.enumerated().map { (index, distance) -> CGPoint in
            let angle = Angle(degrees: 135.0 - (90.0 / Double(distances.count - 1)) * Double(index))
            return CGPoint(
                x: center.x + CGFloat(cos(angle.radians)) * distance,
                y: center.y - CGFloat(sin(angle.radians)) * distance
            )
        }

        return ZStack {
            ForEach(Array(positions.enumerated()), id: \.element) { index, position in
                let isRed = rawDistances[index] <= tooclose
                let fillColor = isRed ? Color.red.opacity(0.5) : Color.green.opacity(0.5)
                
                Path { path in
                    let angle = Angle(degrees: 135.0 - (90.0 / Double(distances.count - 1)) * Double(index))
                    let outerX = center.x + CGFloat(cos(angle.radians)) * maxRadius
                    let outerY = center.y - CGFloat(sin(angle.radians)) * maxRadius

                    path.move(to: CGPoint(x: outerX, y: outerY))
                    path.addLine(to: position)

                    if index < positions.count - 1 {
                        path.addLine(to: positions[index + 1])
                        let nextAngle = Angle(degrees: 135.0 - (90.0 / Double(distances.count - 1)) * Double(index + 1))
                        path.addLine(to: CGPoint(x: center.x + CGFloat(cos(nextAngle.radians)) * maxRadius,
                                                 y: center.y - CGFloat(sin(nextAngle.radians)) * maxRadius))
                    } else {
                        let finalAngle = Angle(degrees: 45)
                        path.addLine(to: CGPoint(x: center.x + CGFloat(cos(finalAngle.radians)) * maxRadius,
                                                 y: center.y - CGFloat(sin(finalAngle.radians)) * maxRadius))
                    }

                    path.closeSubpath()
                }
                .fill(fillColor)
            }

            ForEach(Array(positions.enumerated()), id: \.element) { index, position in
                Circle()
                    .fill(rawDistances[index] <= tooclose ? Color.red : Color.green)
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
    let finalAngle: Double
    let tooclose: CGFloat

    var body: some View {
        let positions = distances.enumerated().map { (index, distance) -> CGPoint in
            let angle = Angle(degrees: startAngle - (90.0 / Double(distances.count - 1)) * Double(index))
            return CGPoint(
                x: center.x + CGFloat(cos(angle.radians)) * distance,
                y: center.y - CGFloat(sin(angle.radians)) * distance
            )
        }

        return ZStack {
            ForEach(Array(positions.enumerated()), id: \.element) { index, position in
                let isRed = rawDistances[index] <= tooclose
                let fillColor = isRed ? Color.red.opacity(0.5) : Color.green.opacity(0.5)
                
                Path { path in
                    let angle = Angle(degrees: startAngle - (90.0 / Double(distances.count - 1)) * Double(index))
                    let outerX = center.x + CGFloat(cos(angle.radians)) * maxRadius
                    let outerY = center.y - CGFloat(sin(angle.radians)) * maxRadius

                    path.move(to: CGPoint(x: outerX, y: outerY))
                    path.addLine(to: position)

                    if index < positions.count - 1 {
                        path.addLine(to: positions[index + 1])
                        let nextAngle = Angle(degrees: startAngle - (90.0 / Double(distances.count - 1)) * Double(index + 1))
                        path.addLine(to: CGPoint(x: center.x + CGFloat(cos(nextAngle.radians)) * maxRadius,
                                                 y: center.y - CGFloat(sin(nextAngle.radians)) * maxRadius))
                    } else {
                        let finalAngle = Angle(degrees: finalAngle)
                        path.addLine(to: CGPoint(x: center.x + CGFloat(cos(finalAngle.radians)) * maxRadius,
                                                 y: center.y - CGFloat(sin(finalAngle.radians)) * maxRadius))
                    }

                    path.closeSubpath()
                }
                .fill(fillColor)
            }

            ForEach(Array(positions.enumerated()), id: \.element) { index, position in
                Circle()
                    .fill(rawDistances[index] <= tooclose ? Color.red : Color.green)
                    .frame(width: 10, height: 10)
                    .position(position)
            }
        }
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

struct OtherBoatsView: View {
    let boats: [(distance: CGFloat, angle: CGFloat)]
    let center: CGPoint
    let scaleDistance: (CGFloat) -> CGFloat

    var body: some View {
        let boatColors: [Color] = [.orange, .yellow, .purple]

        ForEach(Array(boats.enumerated()), id: \.offset) { index, boat in
            let color = boatColors[index % boatColors.count]
            let adjustedAngle = 90 - boat.angle
            let radians = Angle(degrees: Double(adjustedAngle)).radians
            let scaledDistance = scaleDistance(boat.distance)

            let position = CGPoint(
                x: center.x + CGFloat(cos(radians)) * scaledDistance,
                y: center.y - CGFloat(sin(radians)) * scaledDistance
            )

            ZStack {
                // Triangle
                Path { path in
                    let size: CGFloat = 18
                    path.move(to: CGPoint(x: position.x, y: position.y - size / 2))
                    path.addLine(to: CGPoint(x: position.x - size / 2, y: position.y + size / 2))
                    path.addLine(to: CGPoint(x: position.x + size / 2, y: position.y + size / 2))
                    path.closeSubpath()
                }
                .fill(color)
                .overlay(
                    Path { path in
                        let size: CGFloat = 18
                        path.move(to: CGPoint(x: position.x, y: position.y - size / 2))
                        path.addLine(to: CGPoint(x: position.x - size / 2, y: position.y + size / 2))
                        path.addLine(to: CGPoint(x: position.x + size / 2, y: position.y + size / 2))
                        path.closeSubpath()
                    }
                    .stroke(Color.black, lineWidth: 2)
                )
/*
                // Label
                Text("(\(String(format: "%.1f", boat.distance)), \(Int(adjustedAngle)))")
                    .font(.caption2)
                    .foregroundColor(.black)
                    .position(x: position.x, y: position.y - 25)
 */
            }
        }
    }
}


struct PolarGridView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
