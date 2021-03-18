import SwiftUI

struct SplashView: View {
    var begin: (() -> Void)?
    var help: (() -> Void)?

    var body: some View {
        GeometryReader { metrics in
            VStack(spacing:0) {
                Spacer()
                Text("Solving Bee")
                    .foregroundColor(.gray)
                    .bold()
                    .font(.title)
                    .frame(width: metrics.size.width, height: 200)
                ZStack {
                    Image("Reticle")
                        .resizable()
                    Image("ReticleDetectedOverlay")
                        .resizable()
                    Text("Scan")
                        .foregroundColor(.white)
                        .bold()
                        .font(.title)
                }
                .frame(width: metrics.size.width * 0.6, height: metrics.size.width * 0.6)
                .onTapGesture {
                    begin!()
                }
                Text("Scan a New York Times Spelling Bee puzzle to get clues about the words it contains.")
                    .foregroundColor(.gray)
                    .frame(width: metrics.size.width * 0.8, height: 100)
                Spacer()
                Text("Learn more about where to find puzzles and how to scan them.")
                    .foregroundColor(.blue)
                    .underline()
                    .multilineTextAlignment(.leading)
                    .frame(width: metrics.size.width * 0.8, height: 100)
                    .onTapGesture {
                        help!()
                    }
            }
            .frame(width: metrics.size.width, height: metrics.size.height)
        }
        // Ignore safe area insets so that we truly center the image (and thus
        // it lines up with the launch screen and the reticle in the
        // ScanningViewController).
        .edgesIgnoringSafeArea(.all)
    }
}

struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView()
    }
}
