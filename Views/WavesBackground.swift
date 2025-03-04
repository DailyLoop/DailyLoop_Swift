//
//  WavesBackground.swift
//  NewsFlowAI
//
//  Created by Akalpit Dawkhar on 3/3/25.
//
//
//  WavesBackground.swift
//  NewsFlowAI
//
//  Created by Akalpit Dawkhar on 3/3/25.
//

import SwiftUI

struct WavesBackground: View {
    @State private var phase: CGFloat = 0.0
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let amplitude = size.width / 25.0
                context.opacity = 0.1
                
                for i in 0..<10 {
                    var path = Path()
                    let waveHeight = size.height / 2.0
                    path.move(to: CGPoint(x: 0, y: waveHeight))
                    
                    for x in stride(from: 0, to: size.width, by: 5) {
                        let frequency = CGFloat(i + 1) / 15.0
                        let phaseShift = CGFloat(time) * frequency
                        let y = waveHeight + amplitude * sin(((2 * .pi) / 200) * x + phaseShift)
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                    
                    path.addLine(to: CGPoint(x: size.width, y: size.height))
                    path.addLine(to: CGPoint(x: 0, y: size.height))
                    path.closeSubpath()
                    
                    context.stroke(path, with: .color(.blue.opacity(0.3)), lineWidth: 1)
                    context.fill(path, with: .color(.blue.opacity(0.05)))
                }
            }
        }
    }
}

struct WavesBackground_Previews: PreviewProvider {
    static var previews: some View {
        WavesBackground()
    }
}
