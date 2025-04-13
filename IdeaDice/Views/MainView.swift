import SwiftUI

struct MainView: View {
    @State private var selectedTab: Int = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            CardGeneratorView()
                .tabItem {
                    Label("Ideas", systemImage: "lightbulb.fill")
                }
                .tag(0)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(1)
        }
        .frame(width: 500, height: 600)
    }
}

#Preview {
    MainView()
} 