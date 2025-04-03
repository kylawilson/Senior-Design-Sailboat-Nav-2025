import SwiftUI

struct PolarGridView: View {
    let rings: Int = 5 // Number of concentric circles
    let lines: Int = 8 // Number of radial lines
    
    //MARK: Use Below for Integration
    
    let rawOAKDDistances: [CGFloat]
    let rawLeftSPDistances: [CGFloat]
    let rawRightSPDistances: [CGFloat]
    //important note: for the StereoPi, even if we only receive 1 value, we still need an array of at least 10
    //of that value to create a solid bar for the depth
    
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
            //MARK: Initial Data
            GeometryReader { geometry in
                let size = min(geometry.size.width, geometry.size.height)
                let center = CGPoint(x: size / 2, y: size / 2)
                let maxRadius = size / 2
                
                let OAKDobjectDistances = rawOAKDDistances.map { scaleDistance($0) }
                let LeftSPObjectDistances = rawLeftSPDistances.map { scaleDistance($0) }
                let RightSPObjectDistances = rawRightSPDistances.map { scaleDistance($0) }
                
                //MARK: Base Background/MAP
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
                    
                    //MARK: OAK-D Objects
                    
                    // Compute object positions
                    let OAKDobjectPositions = OAKDobjectDistances.enumerated().map { (index, distance) -> CGPoint in
                        let angle = Angle(degrees: 135.0 - (90.0 / Double(OAKDobjectDistances.count - 1)) * Double(index))
                        let radianAngle = angle.radians
                        return CGPoint(
                            x: center.x + cos(radianAngle) * distance,
                            y: center.y - sin(radianAngle) * distance
                        )
                    }
                   

                    ForEach(Array(OAKDobjectPositions.enumerated()), id: \.element) { index, position in
                        let isRed = rawOAKDDistances[index] <= 3
                        let fillColor = isRed ? Color.red.opacity(0.5) : Color.green.opacity(0.5)
                        
                        Path { path in
                            let angle = Angle(degrees: 135.0 - (90.0 / Double(OAKDobjectDistances.count - 1)) * Double(index))
                            let outerX = center.x + cos(angle.radians) * maxRadius
                            let outerY = center.y - sin(angle.radians) * maxRadius

                            path.move(to: CGPoint(x: outerX, y: outerY))
                            path.addLine(to: position)

                            // If this is NOT the last object, connect to the next
                            if index < OAKDobjectPositions.count - 1 {
                                let nextPosition = OAKDobjectPositions[index + 1]
                                path.addLine(to: nextPosition)

                                let nextAngle = Angle(degrees: 135.0 - (90.0 / Double(OAKDobjectDistances.count - 1)) * Double(index + 1))
                                let nextOuterX = center.x + cos(nextAngle.radians) * maxRadius
                                let nextOuterY = center.y - sin(nextAngle.radians) * maxRadius
                                path.addLine(to: CGPoint(x: nextOuterX, y: nextOuterY))
                            }
                            // If this is the last object, ensure we close at exactly 45º
                            else {
                                let correctedOuterX = center.x + cos(Angle(degrees: 45).radians) * maxRadius
                                let correctedOuterY = center.y - sin(Angle(degrees: 45).radians) * maxRadius
                                path.addLine(to: CGPoint(x: correctedOuterX, y: correctedOuterY))
                            }

                            path.closeSubpath()
                        }
                        .fill(fillColor)
                    }


                    // Draw the circles *after* the shaded regions
                    ForEach(Array(OAKDobjectPositions.enumerated()), id: \.element) { index, position in
                        Circle()
                            .fill(rawOAKDDistances[index] <= 3 ? Color.red : Color.green)
                            .frame(width: 10, height: 10)
                            .position(x: position.x, y: position.y)
                    }

                    
                    //MARK: Left StereoPi Camera
                    
                    let LeftSPObjectPositions = LeftSPObjectDistances.enumerated().map { (index, distance) -> CGPoint in
                        let angle = Angle(degrees: 225.0 - (90.0 / Double(LeftSPObjectDistances.count - 1)) * Double(index))
                        let radianAngle = angle.radians
                        return CGPoint(
                            x: center.x + cos(radianAngle) * distance,
                            y: center.y - sin(radianAngle) * distance
                        )
                    }
                    
                    // Shade above yellow objects within outer circle
                    Path { path in
                        for (index, position) in LeftSPObjectPositions.enumerated() {
                            let angle = Angle(degrees: 225.0 - (90.0 / Double(LeftSPObjectDistances.count - 1)) * Double(index))
                            let outerX = center.x + cos(angle.radians) * maxRadius
                            let outerY = center.y - sin(angle.radians) * maxRadius
                            
                            if index == 0 {
                                path.move(to: CGPoint(x: outerX, y: outerY))
                            }
                            path.addLine(to: position)
                        }
                        for index in (0..<LeftSPObjectPositions.count).reversed() {
                            let angle = Angle(degrees: 225.0 - (90.0 / Double(LeftSPObjectDistances.count - 1)) * Double(index))
                            let outerX = center.x + cos(angle.radians) * maxRadius
                            let outerY = center.y - sin(angle.radians) * maxRadius
                            path.addLine(to: CGPoint(x: outerX, y: outerY))
                        }
                        path.closeSubpath()
                    }
                    //.fill(Color.yellow.opacity(0.5))
                    .fill(rawLeftSPDistances.contains(where: { $0 <= 3 }) ? Color.red.opacity(0.5) : Color.yellow.opacity(0.5))
                    
                   /*
                   
                    // Yellow Objects
                    ForEach(LeftSPObjectPositions, id: \ .self) { position in
                        Circle()
                            .fill(Color.yellow)
                            .frame(width: 10, height: 10)
                            .position(x: position.x, y: position.y)
                    }
                    */
                    
                    //MARK: Right StereoPi Camera
            
                    let RightSPObjectPositions = RightSPObjectDistances.enumerated().map { (index, distance) -> CGPoint in
                        let angle = Angle(degrees: 45.0 - (90.0 / Double(RightSPObjectDistances.count - 1)) * Double(index))
                        let radianAngle = angle.radians
                        return CGPoint(
                            x: center.x + cos(radianAngle) * distance,
                            y: center.y - sin(radianAngle) * distance
                        )
                    }
                    
                    Path { path in
                        for (index, position) in RightSPObjectPositions.enumerated() {
                            let angle = Angle(degrees: 45.0 - (90.0 / Double(RightSPObjectDistances.count - 1)) * Double(index))
                            let outerX = center.x + cos(angle.radians) * maxRadius
                            let outerY = center.y - sin(angle.radians) * maxRadius
                            
                            if index == 0 {
                                path.move(to: CGPoint(x: outerX, y: outerY))
                            }
                            path.addLine(to: position)
                        }
                        for index in (0..<RightSPObjectPositions.count).reversed() {
                            let angle = Angle(degrees: 45.0 - (90.0 / Double(RightSPObjectDistances.count - 1)) * Double(index))
                            let outerX = center.x + cos(angle.radians) * maxRadius
                            let outerY = center.y - sin(angle.radians) * maxRadius
                            path.addLine(to: CGPoint(x: outerX, y: outerY))
                        }
                        path.closeSubpath()
                    }
                    .fill(rawRightSPDistances.contains(where: { $0 <= 3 }) ? Color.red.opacity(0.5) : Color.yellow.opacity(0.5))
                    
                    /*
                    // Yellow Objects
                    ForEach(RightSPObjectPositions, id: \ .self) { position in
                        Circle()
                            .fill(Color.yellow)
                            .frame(width: 10, height: 10)
                            .position(x: position.x, y: position.y)
                    }
                     */
                    
                    
                    //MARK: White Triangle Representing Boat
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
