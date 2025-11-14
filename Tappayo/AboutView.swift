import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack {
            Text("Tappayo - the simple Tap to Pay app")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.bottom, 8)

            Text("Contact: markmoriarty@stripe.com")
                .font(.body)
                .padding()
            
            Text("Slack: #simple-mobile-payments-app")
                .font(.body)
                .padding()
            
            Text("Collect payments swift,\nIn person with ease and grace,\nTech meets human touch.")
                .font(.body)
                .italic()
                .padding()
            
            Spacer()
        }
        .padding()
        .navigationTitle("About")
        // .navigationBarTitleDisplayMode(.inline)
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}
