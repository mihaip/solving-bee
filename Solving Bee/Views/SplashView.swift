import SwiftUI

struct SplashView: View {
    var begin: (() -> Void)?

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
                    .frame(width: metrics.size.width * 0.8, height: 140)
                Spacer()
                Text("Not affiliated with the New York Times.")
                    .font(.footnote)
                    .foregroundColor(Color(white:0.4))
                    .frame(width: metrics.size.width * 0.8, height: 60)
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
