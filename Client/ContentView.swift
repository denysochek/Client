import SwiftUI

// MARK: - App Redirect
struct ContentView: View {
    var body: some View {
        MainView()
            .frame(minWidth: 1000, minHeight: 700)
    }
}

// MARK: - Main Interface
struct MainView: View {
    @State private var selectedInstance: GameInstance?
    // Стан для відстеження активної вкладки в тулбарі
    @State private var activeTab: String = "LOG"
    // Стан для керування видимістю правої панелі
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    
    @State private var instances = [
        GameInstance(name: "SoftWind", version: "1.19.2 Forge", category: "General"),
        GameInstance(name: "1.12.2 Forge", version: "1.12.2", category: "General"),
        GameInstance(name: "1.16.5 Fabric", version: "1.16.5", category: "General"),
        GameInstance(name: "reCrafted Optima", version: "1.20.1", category: "reCrafted"),
        GameInstance(name: "reCrafted Industria", version: "1.12.2", category: "reCrafted")
    ]

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // MARK: - Sidebar (Left)
            VStack(spacing: 0) {
                List(selection: $selectedInstance) {
                    ForEach(["General", "reCrafted"], id: \.self) { category in
                        Section(header: Text(category.uppercased())
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)) {
                            ForEach(instances.filter { $0.category == category }) { instance in
                                NavigationLink(value: instance) {
                                    Label(instance.name, systemImage: "cube.box.fill")
                                }
                            }
                        }
                    }
                }
                .listStyle(.sidebar)

                Spacer()
                UserProfileView()
            }
            .navigationSplitViewColumnWidth(min: 220, ideal: 240, max: 300)

        } content: {
            // MARK: - Main Content (Center)
            ZStack {
                Color(NSColor.textBackgroundColor)
                VStack(spacing: 16) {
                    Image(systemName: "square.stack.3d.up")
                        .font(.system(size: 72, weight: .thin))
                        .foregroundColor(.secondary.opacity(0.2))
                    
                    VStack(spacing: 4) {
                        Text(selectedInstance?.name ?? "Select Instance")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        Text("Active Tab: \(activeTab)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(selectedInstance?.name ?? "reCrafted Client")
                            .font(.headline)
                        Text(selectedInstance?.version ?? "Ready to play")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                ToolbarItemGroup(placement: .primaryAction) {
                    // Група вкладок з логікою перемикання
                    HStack(spacing: 0) {
                        TabButton(icon: "doc.text", label: "LOG", activeTab: $activeTab)
                        TabButton(icon: "puzzlepiece", label: "MODS", activeTab: $activeTab)
                        TabButton(icon: "archivebox", label: "RES", activeTab: $activeTab)
                        TabButton(icon: "sun.max", label: "SHADERS", activeTab: $activeTab)
                        TabButton(icon: "globe", label: "WORLDS", activeTab: $activeTab)
                    }
                    .background(Color.primary.opacity(0.05))
                    .cornerRadius(8)
                    .padding(.trailing, 8)
                    
                    Button(action: {}) {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                    .tint(.orange)
                    
                    // Кнопка закриття/відкриття правої панелі
                    Button(action: {
                        withAnimation {
                            if columnVisibility == .all {
                                columnVisibility = .doubleColumn
                            } else {
                                columnVisibility = .all
                            }
                        }
                    }) {
                        Label("Toggle Sidebar", systemImage: "sidebar.right")
                    }
                }
            }

        } detail: {
            // MARK: - Detail Panel (Right)
            ActionPanelView(instance: selectedInstance ?? instances[0])
                .navigationSplitViewColumnWidth(min: 280, ideal: 300, max: 350)
        }
    }
}

// MARK: - Custom Tab Button
struct TabButton: View {
    let icon: String
    let label: String
    @Binding var activeTab: String
    
    var isActive: Bool { activeTab == label }
    
    var body: some View {
        Button(action: { activeTab = label }) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: isActive ? .bold : .regular))
                Text(label)
                    .font(.system(size: 8, weight: .bold))
            }
            .frame(width: 48, height: 32)
            .background(isActive ? Color.accentColor.opacity(0.15) : Color.clear)
            .foregroundColor(isActive ? .accentColor : .secondary)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Data Models
struct GameInstance: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let version: String
    let category: String
}

// MARK: - Subviews

struct UserProfileView: View {
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.pink, .purple], startPoint: .top, endPoint: .bottom))
                    Text("D")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(width: 32, height: 32)
                
                VStack(alignment: .leading, spacing: 0) {
                    Text("Denysocheck")
                        .font(.system(size: 13, weight: .semibold))
                    HStack(spacing: 4) {
                        Circle().fill(.green).frame(width: 6, height: 6)
                        Text("Online")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(.ultraThinMaterial)
        }
    }
}

struct ActionPanelView: View {
    let instance: GameInstance
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(LinearGradient(colors: [.blue.opacity(0.8), .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .shadow(color: .blue.opacity(0.3), radius: 15, x: 0, y: 8)
                        
                        Image(systemName: "cube.fill")
                            .font(.system(size: 54))
                            .foregroundColor(.white)
                    }
                    .frame(width: 100, height: 100)
                    
                    VStack(spacing: 4) {
                        Text(instance.name)
                            .font(.title3)
                            .fontWeight(.bold)
                        Text(instance.version)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 48)
                
                VStack(spacing: 14) {
                    Button(action: {}) {
                        Label("Launch Game", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                            .fontWeight(.semibold)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(.green)
                    
                    Button(action: {}) {
                        Label("Stop", systemImage: "stop.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .tint(.red)
                    
                    Divider().padding(.vertical, 10)
                    
                    VStack(spacing: 8) {
                        SecondaryActionButton(icon: "gearshape", label: "Instance Settings")
                        SecondaryActionButton(icon: "folder", label: "Open Folder")
                        SecondaryActionButton(icon: "trash", label: "Delete Instance", color: .red)
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
        }
        .background(.ultraThinMaterial)
    }
}

struct SecondaryActionButton: View {
    let icon: String
    let label: String
    var color: Color = .primary
    
    var body: some View {
        Button(action: {}) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 18, alignment: .leading)
                Text(label)
                    .font(.subheadline)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(Color.primary.opacity(0.04))
        .cornerRadius(8)
        .foregroundColor(color)
    }
}

#Preview {
    ContentView()
}
