import SwiftUI

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
            //.background(Color.blue.edgesIgnoringSafeArea(.all))
        }
    }
}

struct CircleData: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var label: String
    var realX: Double
    var realY: Double
}

struct MovingCirclesView: View {
    @State private var circles: [CircleData] = []
    @State private var rst: Bool = false
    @State private var num_circles: Int = 3
    //@State private var circlePositions: [(realX: Double, realY: Double, label: String)] = []
    
    let circleLabels = ["Sailboat", "Buoy", "Motor Boat","Unknown"]
    let maxDistance: Double = 15.0  // Max sensor range
    let maxXRange: Double = 10.0
    let circlePositions: [(realX: Double, realY: Double, label: String)] =
    [(realX:3, realY: 10, "Sailboat"),
     (realX:-5, realY: 6, "Buoy"),
     (realX:8, realY:3, "Motor Boat"),
     (realX:-8, realY: 12, "Buoy"),
     (realX:13, realY: 8, "Buoy")]
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Triangle
                Triangle()
                    .fill(Color.white)
                    .overlay(Triangle().stroke(Color.black, lineWidth: 3))
                    .frame(width: 35, height: 35)
                    .position(x: geometry.size.width / 2, y: geometry.size.height * 0.95)
                
                // Circles
                ForEach(circles) { circle in
                    ZStack{
                        Circle()
                            .fill(Color.pink)
                            .overlay(Circle().stroke(Color.black, lineWidth: 3))
                            .frame(width: 30, height: 30)
                            .position(x: circle.x, y: circle.y)
                        Text(circle.label)
                            .font(.system(size: 24, weight: .semibold))
                        //.font(.caption)
                            .foregroundColor(.white)
                            .offset(y:-25)
                            .position(x: circle.x, y: circle.y)
                        Text("(\(String(format: "%.1f", circle.realX)), \(String(format: "%.1f", circle.realY))) m")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .offset(y: 25)
                            .position(x: circle.x, y: circle.y)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.blue.edgesIgnoringSafeArea(.all))
            .onAppear {
                let screenWidth = geometry.size.width
                let screenHeight = geometry.size.height
                //initializePositions()//realX:realX, realY:realY, label:circleLabels)
                addCircles(screenWidth: screenWidth, screenHeight: screenHeight, triangleX: geometry.size.width / 2, triangleY: geometry.size.height * 0.95)
            }
        }
    }
    
    func scaledXPosition(realX: Double, screenWidth: CGFloat, triangleX: CGFloat) -> CGFloat {
        let minX = triangleX - (screenWidth / 3)  // Scale leftward range
        let maxX = triangleX + (screenWidth / 3)  // Scale rightward range
        return minX + ((realX + maxXRange) / (2 * maxXRange)) * (maxX - minX)
    }
    
    func scaledYPosition(realDistance: Double, screenHeight: CGFloat) -> CGFloat {
        let minY = screenHeight * 0.1 // Objects at 15m appear near the top
        let maxY = screenHeight * 0.9 // Objects at 0m appear near the bottom
        return maxY - ((realDistance / maxDistance) * (maxY - minY))
    }
    
    func addCircles(screenWidth: CGFloat, screenHeight: CGFloat, triangleX: CGFloat, triangleY: CGFloat) {
        //, circlePositions:[(realX: Double, realY: Double, label: String)]
        if rst {
            circles.removeAll()
        }
        else {
            /*
             circles = (0..<num_circles).map { i in
             CircleData(x: circlePositions[i].0, y: circlePositions[i].1, label: circlePositions[i].2)
             */
            
            /* circles = circles.map { circle in
             CircleData(screenX: scaledXPosition(realX: circlePositions.realX, screenWidth: screenWidth, triangleX: triangleX),
             screenY: scaledYPosition(realY: circlePositions.realY, screenHeight: screenHeight, triangleY: triangleY),
             label: circle.label,
             realX: circle.realX,
             realY: circle.realY)
             } */
            circles = circlePositions.prefix(num_circles).map { pos in
                CircleData(
                    x: scaledXPosition(realX: pos.realX, screenWidth: screenWidth, triangleX: triangleX),
                    y: scaledYPosition(realDistance: pos.realY, screenHeight: screenHeight),
                    label: pos.label,
                    realX: pos.realX,
                    realY: pos.realY
                )
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
}
    struct ContentView: View {
        var body: some View {
            ZStack{
                MovingCirclesView()
                GridView(rows: 10, columns: 10)
                    .opacity(0.5)
            }
            .edgesIgnoringSafeArea(.all)
        }
    }
    

