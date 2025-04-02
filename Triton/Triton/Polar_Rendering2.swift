//
//  ContentView.swift
//  phone_polar_map
//
//  Created by Diego D’Angelo-Cosme on 3/31/25.
//

/* Base case no shading version
import SwiftUI

struct Object {
    let distance: CGFloat // Distance from the center
}

struct PolarGridView: View {
    let rings: Int = 5 // Number of concentric circles
    let lines: Int = 8 // Number of radial lines
   // let objectDistances: [CGFloat] = [50, 100, 150, 200, 75, 100, 100, 200, 45, 15]// Example distances for objects
    //let objectDistances: [CGFloat] = [25, 25, 25, 25, 25, 25, 25, 25, 25]
    let objectDistances: [CGFloat] = [200, 200, 200, 200, 175, 150, 120, 100, 80, 75]
    
    //maximum in the circle is 200
    //minimum is 25
    
    var body: some View {
        ZStack {
            // Background
            Color.white.opacity(1.0)
                .edgesIgnoringSafeArea(.all)
            
            // Polar Grid
            GeometryReader { geometry in
                let size = min(geometry.size.width, geometry.size.height)
                let center = CGPoint(x: size / 2, y: size / 2)
                let maxRadius = size / 2
                
                ZStack(alignment: .center) {
                    // Radial Lines
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
                    
                    // Concentric Circles
                    ForEach(1...rings, id: \.self) { index in
                        Circle()
                            .stroke(Color.blue, lineWidth: 1.5)
                            .frame(width: CGFloat(index) / CGFloat(rings) * maxRadius * 2,
                                   height: CGFloat(index) / CGFloat(rings) * maxRadius * 2)
                    }
                    
                    // Small White Triangle in Center
                    Path { path in
                        let triangleSize: CGFloat = 20
                        path.move(to: CGPoint(x: center.x, y: center.y - triangleSize / 2))
                        path.addLine(to: CGPoint(x: center.x - triangleSize / 2, y: center.y + triangleSize / 2))
                        path.addLine(to: CGPoint(x: center.x + triangleSize / 2, y: center.y + triangleSize / 2))
                        path.closeSubpath()
                    }
                    .fill(Color.white)
                    .stroke(Color.black, lineWidth: 2)
                    
                    // Compute object positions
                   // let angles = stride(from: 45.0, through: 135.0, by: 90.0 / Double(objectDistances.count - 1))
                    let objectPositions = objectDistances.enumerated().map { (index, distance) -> CGPoint in
                        let angle = Angle(degrees: 45.0 + (90.0 / Double(objectDistances.count - 1)) * Double(index))
                        let radianAngle = angle.radians
                        return CGPoint(
                            x: center.x + cos(radianAngle) * distance,
                            y: center.y + sin(radianAngle) * -distance // Negative to place in top quadrant
                        )
                    }
                    
                    // Draw green line connecting the objects
                    Path { path in
                        guard let first = objectPositions.first else { return }
                        path.move(to: first)
                        for position in objectPositions.dropFirst() {
                            path.addLine(to: position)
                        }
                    }
                    .stroke(Color.green, lineWidth: 2)
                    
                    // Objects as Green Circles
                    ForEach(objectPositions, id: \.self) { position in
                        Circle()
                            .fill(Color.green)
                            .frame(width: 10, height: 10)
                            .position(x: position.x, y: position.y)
                    }
                }
                .frame(width: size, height: size)
                .position(x: geometry.size.width / 2, y: geometry.size.height * 0.35)
            }
        }
    }
}

struct ContentView: View {
    var body: some View {
        PolarGridView()
    }
}

struct PolarGridView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
*/
/*
 //Area beneath the curve shading
import SwiftUI

struct PolarGridView: View {
    let rings: Int = 5 // Number of concentric circles
    let lines: Int = 8 // Number of radial lines
    //let objectDistances: [CGFloat] = [200, 200, 200, 200, 175, 150, 120, 100, 80, 75]
    //let objectDistances: [CGFloat] = [200, 200, 200, 200, 200, 200, 200, 200, 200, 200]
    let objectDistances: [CGFloat] = [87.5, 87.5, 87.5, 87.5, 87.5, 87.5, 87.5, 87.5, 87.5, 87.5]
    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)
            
            GeometryReader { geometry in
                let size = min(geometry.size.width, geometry.size.height)
                let center = CGPoint(x: size / 2, y: size / 2)
                let maxRadius = size / 2
                
                ZStack {
                    // Concentric Circles
                    ForEach(1...rings, id: \.self) { index in
                        Circle()
                            .stroke(Color.blue, lineWidth: 1.5)
                            .frame(width: CGFloat(index) / CGFloat(rings) * maxRadius * 2,
                                   height: CGFloat(index) / CGFloat(rings) * maxRadius * 2)
                    }
                    
                    // Radial Lines
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
                    
                    // Compute object positions
                    let objectPositions = objectDistances.enumerated().map { (index, distance) -> CGPoint in
                        let angle = Angle(degrees: 45.0 + (90.0 / Double(objectDistances.count - 1)) * Double(index))
                        let radianAngle = angle.radians
                        return CGPoint(
                            x: center.x + cos(radianAngle) * distance,
                            y: center.y - sin(radianAngle) * distance
                        )
                    }
                    
                    // Green Filled Regions
                    Path { path in
                        path.move(to: center)
                        for position in objectPositions {
                            path.addLine(to: position)
                        }
                        path.addLine(to: center)
                    }
                    .fill(Color.green.opacity(0.5))
                    
                    // Green Connecting Line
                    Path { path in
                        guard let first = objectPositions.first else { return }
                        path.move(to: first)
                        for position in objectPositions.dropFirst() {
                            path.addLine(to: position)
                        }
                    }
                    .stroke(Color.green, lineWidth: 2)
                    
                    // Objects as Green Circles
                    ForEach(objectPositions, id: \.self) { position in
                        Circle()
                            .fill(Color.green)
                            .frame(width: 10, height: 10)
                            .position(x: position.x, y: position.y)
                    }
                    
                    // Small White Triangle in Center
                    Path { path in
                        let triangleSize: CGFloat = 20
                        path.move(to: CGPoint(x: center.x, y: center.y - triangleSize / 2))
                        path.addLine(to: CGPoint(x: center.x - triangleSize / 2, y: center.y + triangleSize / 2))
                        path.addLine(to: CGPoint(x: center.x + triangleSize / 2, y: center.y + triangleSize / 2))
                        path.closeSubpath()
                    }
                    .fill(Color.white)
                    .stroke(Color.black, lineWidth: 2)
                }
                .frame(width: size, height: size)
                .position(x: geometry.size.width / 2, y: geometry.size.height * 0.35)
            }
        }
    }
}

struct ContentView: View {
    var body: some View {
        PolarGridView()
    }
}

struct PolarGridView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
*/

/*
//Area above the curve shading
import SwiftUI

struct PolarGridView: View {
    let rings: Int = 5 // Number of concentric circles
    let lines: Int = 8 // Number of radial lines
    //let objectDistances: [CGFloat] = [45, 65, 95, 120, 150, 165, 180, 190, 200, 200]
    //let objectDistances: [CGFloat] = [200, 200, 200, 200, 200, 200, 200, 200, 200, 200, 200]
    //let objectDistances: [CGFloat] = [87.5, 87.5, 87.5, 87.5, 87.5, 87.5, 87.5, 87.5, 87.5, 87.5]
    let objectDistances: [CGFloat] = [25, 25, 25, 25, 25, 25, 25, 25, 25, 25]
    
    
    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)
            
            GeometryReader { geometry in
                let size = min(geometry.size.width, geometry.size.height)
                let center = CGPoint(x: size / 2, y: size / 2)
                let maxRadius = size / 2
                
                ZStack {
                    // Concentric Circles
                    ForEach(1...rings, id: \ .self) { index in
                        Circle()
                            .stroke(Color.blue, lineWidth: 1.5)
                            .frame(width: CGFloat(index) / CGFloat(rings) * maxRadius * 2,
                                   height: CGFloat(index) / CGFloat(rings) * maxRadius * 2)
                    }
                    
                    // Radial Lines
                    ForEach(0..<lines, id: \ .self) { index in
                        Path { path in
                            let angle = Angle.degrees(Double(index) / Double(lines) * 360)
                            let endX = center.x + cos(angle.radians) * maxRadius
                            let endY = center.y + sin(angle.radians) * maxRadius
                            path.move(to: center)
                            path.addLine(to: CGPoint(x: endX, y: endY))
                        }
                        .stroke(Color.blue, lineWidth: 1.5)
                    }
                    
                    // Compute object positions
                    let objectPositions = objectDistances.enumerated().map { (index, distance) -> CGPoint in
                        let angle = Angle(degrees: 135.0 - (90.0 / Double(objectDistances.count - 1)) * Double(index))
                        let radianAngle = angle.radians
                        return CGPoint(
                            x: center.x + cos(radianAngle) * distance,
                            y: center.y - sin(radianAngle) * distance
                        )
                    }
                    
                    // Shade above objects within outer circle
                    Path { path in
                        for (index, position) in objectPositions.enumerated() {
                            let angle = Angle(degrees: 135.0 - (90.0 / Double(objectDistances.count - 1)) * Double(index))
                            let outerX = center.x + cos(angle.radians) * maxRadius
                            let outerY = center.y - sin(angle.radians) * maxRadius
                            
                            if index == 0 {
                                path.move(to: CGPoint(x: outerX, y: outerY))
                            }
                            path.addLine(to: position)
                        }
                        for index in (0..<objectPositions.count).reversed() {
                            let angle = Angle(degrees: 135.0 - (90.0 / Double(objectDistances.count - 1)) * Double(index))
                            let outerX = center.x + cos(angle.radians) * maxRadius
                            let outerY = center.y - sin(angle.radians) * maxRadius
                            path.addLine(to: CGPoint(x: outerX, y: outerY))
                        }
                        path.closeSubpath()
                    }
                    .fill(Color.green.opacity(0.5))
                    
                    // Green Connecting Line
                    Path { path in
                        guard let first = objectPositions.first else { return }
                        path.move(to: first)
                        for position in objectPositions.dropFirst() {
                            path.addLine(to: position)
                        }
                    }
                    .stroke(Color.green, lineWidth: 2)
                    
                    // Objects as Green Circles
                    ForEach(objectPositions, id: \ .self) { position in
                        Circle()
                            .fill(Color.green)
                            .frame(width: 10, height: 10)
                            .position(x: position.x, y: position.y)
                    }
                    
                    // Small White Triangle in Center
                    Path { path in
                        let triangleSize: CGFloat = 20
                        path.move(to: CGPoint(x: center.x, y: center.y - triangleSize / 2))
                        path.addLine(to: CGPoint(x: center.x - triangleSize / 2, y: center.y + triangleSize / 2))
                        path.addLine(to: CGPoint(x: center.x + triangleSize / 2, y: center.y + triangleSize / 2))
                        path.closeSubpath()
                    }
                    .fill(Color.white)
                    .stroke(Color.black, lineWidth: 2)
                }
                .frame(width: size, height: size)
                .position(x: geometry.size.width / 2, y: geometry.size.height * 0.35)
            }
        }
    }
}

struct ContentView: View {
    var body: some View {
        PolarGridView()
    }
}

struct PolarGridView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

*/

//doing the scaling math
import SwiftUI

struct PolarGridView: View {
    let rings: Int = 5 // Number of concentric circles
    let lines: Int = 8 // Number of radial lines
    //let rawObjectDistances_OAK_D: [CGFloat] = [15, 15, 15, 15, 15, 15, 15, 15, 15, 15] // Example values in range [0.5, 15]
    //let rawObjectDistances_OAK_D: [CGFloat] = [7.75, 7.75, 7.75, 7.75, 7.75, 7.75, 7.75, 7.75, 7.75, 7.75]
    //let rawObjectDistances_OAK_D: [CGFloat] = [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5]
    //let rawObjectDistances_OAK_D: [CGFloat] = [3, 5, 7.5, 10, 10, 13.25, 15, 15, 13.76, 12]
    var rawObjectDistances_OAK_D: [CGFloat]
    
    // Scaling function to map values from [0.5, 15] to [25, 200]
    func scaleDistance(_ value: CGFloat) -> CGFloat {
        let minInput: CGFloat = 0.5
        let maxInput: CGFloat = 15
        let minOutput: CGFloat = 25
        let maxOutput: CGFloat = 200
        return ((value - minInput) / (maxInput - minInput)) * (maxOutput - minOutput) + minOutput
    }
    
    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)
            
            GeometryReader { geometry in
                let size = min(geometry.size.width, geometry.size.height)
                let center = CGPoint(x: size / 2, y: size / 2)
                let maxRadius = size / 2
                
                let objectDistances = rawObjectDistances_OAK_D.map { scaleDistance($0) }
                
                ZStack {
                    // Concentric Circles
                    ForEach(1...rings, id: \ .self) { index in
                        Circle()
                            .stroke(Color.blue, lineWidth: 1.5)
                            .frame(width: CGFloat(index) / CGFloat(rings) * maxRadius * 2,
                                   height: CGFloat(index) / CGFloat(rings) * maxRadius * 2)
                    }
                    
                    // Radial Lines
                    ForEach(0..<lines, id: \ .self) { index in
                        Path { path in
                            let angle = Angle.degrees(Double(index) / Double(lines) * 360)
                            let endX = center.x + cos(angle.radians) * maxRadius
                            let endY = center.y + sin(angle.radians) * maxRadius
                            path.move(to: center)
                            path.addLine(to: CGPoint(x: endX, y: endY))
                        }
                        .stroke(Color.blue, lineWidth: 1.5)
                    }
                    
                    // Compute object positions
                    let objectPositions = objectDistances.enumerated().map { (index, distance) -> CGPoint in
                        let angle = Angle(degrees: 135.0 - (90.0 / Double(objectDistances.count - 1)) * Double(index))
                        let radianAngle = angle.radians
                        return CGPoint(
                            x: center.x + cos(radianAngle) * distance,
                            y: center.y - sin(radianAngle) * distance
                        )
                    }
                    
                    // Shade above objects within outer circle
                    Path { path in
                        for (index, position) in objectPositions.enumerated() {
                            let angle = Angle(degrees: 135.0 - (90.0 / Double(objectDistances.count - 1)) * Double(index))
                            let outerX = center.x + cos(angle.radians) * maxRadius
                            let outerY = center.y - sin(angle.radians) * maxRadius
                            
                            if index == 0 {
                                path.move(to: CGPoint(x: outerX, y: outerY))
                            }
                            path.addLine(to: position)
                        }
                        for index in (0..<objectPositions.count).reversed() {
                            let angle = Angle(degrees: 135.0 - (90.0 / Double(objectDistances.count - 1)) * Double(index))
                            let outerX = center.x + cos(angle.radians) * maxRadius
                            let outerY = center.y - sin(angle.radians) * maxRadius
                            path.addLine(to: CGPoint(x: outerX, y: outerY))
                        }
                        path.closeSubpath()
                    }
                    .fill(Color.green.opacity(0.5))
                    
                    // Green Connecting Line
                    Path { path in
                        guard let first = objectPositions.first else { return }
                        path.move(to: first)
                        for position in objectPositions.dropFirst() {
                            path.addLine(to: position)
                        }
                    }
                    .stroke(Color.green, lineWidth: 2)
                    
                    // Objects as Green Circles
                    ForEach(objectPositions, id: \ .self) { position in
                        Circle()
                            .fill(Color.green)
                            .frame(width: 10, height: 10)
                            .position(x: position.x, y: position.y)
                    }
                    
                    // Small White Triangle in Center
                    Path { path in
                        let triangleSize: CGFloat = 20
                        path.move(to: CGPoint(x: center.x, y: center.y - triangleSize / 2))
                        path.addLine(to: CGPoint(x: center.x - triangleSize / 2, y: center.y + triangleSize / 2))
                        path.addLine(to: CGPoint(x: center.x + triangleSize / 2, y: center.y + triangleSize / 2))
                        path.closeSubpath()
                    }
                    .fill(Color.white)
                    .stroke(Color.black, lineWidth: 2)
                }
                .frame(width: size, height: size)
                .position(x: geometry.size.width / 2, y: geometry.size.height * 0.35)
            }
        }
    }
}


struct PolarGridView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
