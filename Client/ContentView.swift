//
//  ContentView.swift
//  Client
//
//  Created by Денис Юрієвич on 13.07.2025.
//

import SwiftUI

// MARK: - Model
enum SidebarItem: Identifiable, Hashable, Equatable {
    case group(id: UUID = UUID(), name: String, children: [SidebarItem])
    case instance(id: UUID = UUID(), name: String)

    var id: UUID {
        switch self {
        case .group(let id, _, _): return id
        case .instance(let id, _): return id
        }
    }

    var title: String {
        switch self {
        case .group(_, let name, _): return name
        case .instance(_, let name): return name
        }
    }

    var isGroup: Bool {
        if case .group = self { return true }
        return false
    }

    func updatedName(_ newName: String) -> SidebarItem {
        switch self {
        case .group(let id, _, let children):
            return .group(id: id, name: newName, children: children)
        case .instance(let id, _):
            return .instance(id: id, name: newName)
        }
    }

    func updatedChildren(_ newChildren: [SidebarItem]) -> SidebarItem {
        switch self {
        case .group(let id, let name, _):
            return .group(id: id, name: name, children: newChildren)
        case .instance:
            return self
        }
    }
}

// MARK: - Store
class SidebarStore: ObservableObject {
    @Published var items: [SidebarItem] = [
        .instance(name: "SoftWind"),
        .instance(name: "1.12.2 Forge"),
        .instance(name: "1.16.5 Fabric"),
        .group(name: "reCrafted", children: [
            .instance(name: "reCrafted Optima"),
            .instance(name: "reCrafted Industria")
        ])
    ]

    @Published var selected: SidebarItem? = nil
    @Published var renamingItem: SidebarItem? = nil
    @Published var dragItem: SidebarItem? = nil
    @Published var dropTarget: (group: Int?, index: Int?)? = nil
}

// MARK: - ContentView
struct ContentView: View {
    @StateObject private var store = SidebarStore()

    var body: some View {
        NavigationSplitView {
            SidebarView()
                .environmentObject(store)
                .frame(minWidth: 198)
        } detail: {
            DetailView()
                .environmentObject(store)
        }
        .frame(minWidth: 200, minHeight: 500)
    }
}

// MARK: - SidebarView
struct SidebarView: View {
    @EnvironmentObject var store: SidebarStore

    var body: some View {
        List(selection: $store.selected) {
            ForEach(store.items.indices, id: \.self) { index in
                let item = store.items[index]
                switch item {
                case .instance:
                    SidebarRow(item: item)
                        .environmentObject(store)

                case .group(let id, _, let children):
                    Section {
                        if children.isEmpty {
                            Text("Drop here")
                                .foregroundColor(.secondary)
                                .padding(.leading, 20)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .onDrop(of: [.text], delegate: EmptyGroupDropTarget(groupIndex: index, store: store))
                        } else {
                            ForEach(children.indices, id: \.self) { childIndex in
                                SidebarRow(item: children[childIndex], groupIndex: index)
                                    .environmentObject(store)
                            }
                        }
                    } header: {
                        SidebarRow(item: item)
                            .environmentObject(store)
                    }
                }
            }
        }

        .listStyle(SidebarListStyle())
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Create Instance") {
                        let item = SidebarItem.instance(name: "New Instance")
                        store.items.append(item)
                        store.renamingItem = item
                        store.selected = item
                    }
                    Button("Create Group") {
                        let group = SidebarItem.group(name: "New Group", children: [])
                        store.items.append(group)
                        store.renamingItem = group
                        store.selected = group
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }
}

// MARK: - SidebarRow
struct SidebarRow: View {
    @EnvironmentObject var store: SidebarStore
    let item: SidebarItem
    var groupIndex: Int? = nil
    @State private var newName: String = ""

    var body: some View {
        VStack(spacing: 0) {
            InsertIndicator()
                .opacity(isDropTarget ? 1 : 0)

            Group {
                if store.renamingItem == item {
                    TextField("", text: $newName, onCommit: commitRename)
                        .textFieldStyle(PlainTextFieldStyle())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .onAppear { newName = item.title }
                        .tag(item)
                } else {
                    Text(item.title)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contextMenu {
                            Button("Rename") { store.renamingItem = item }
                            Button("Delete", role: .destructive) { delete() }
                        }
                        .onDrag {
                            store.dragItem = item
                            return NSItemProvider(object: item.title as NSString)
                        }
                        .onDrop(of: [.text], delegate: DropTarget(item: item, groupIndex: groupIndex, store: store))
                        .tag(item)
                }
            }
        }
    }

    var isDropTarget: Bool {
        guard let drop = store.dropTarget else { return false }

        if let g = groupIndex,
           store.items.indices.contains(g),
           case .group(_, _, let children) = store.items[g],
           let idx = children.firstIndex(of: item) {
            return drop.group == g && drop.index == idx
        } else if groupIndex == nil,
                  let idx = store.items.firstIndex(of: item) {
            return drop.group == nil && drop.index == idx
        }

        return false
    }

    func commitRename() {
        guard !newName.isEmpty else {
            store.renamingItem = nil
            return
        }

        if let idx = store.items.firstIndex(of: item) {
            store.items[idx] = item.updatedName(newName)
        } else if let groupIdx = groupIndex,
                  store.items.indices.contains(groupIdx),
                  case .group(let id, let name, var children) = store.items[groupIdx],
                  let childIdx = children.firstIndex(of: item) {
            children[childIdx] = item.updatedName(newName)
            store.items[groupIdx] = .group(id: id, name: name, children: children)
        }

        store.renamingItem = nil
    }

    func delete() {
        if let idx = store.items.firstIndex(of: item) {
            store.items.remove(at: idx)
        } else if let groupIdx = groupIndex,
                  store.items.indices.contains(groupIdx),
                  case .group(let id, let name, var children) = store.items[groupIdx],
                  let childIdx = children.firstIndex(of: item) {
            children.remove(at: childIdx)
            store.items[groupIdx] = .group(id: id, name: name, children: children)
        }
    }
}

struct InsertIndicator: View {
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color.accentColor)
                .frame(width: 6, height: 6)
            Rectangle()
                .fill(Color.accentColor)
                .frame(height: 2)
        }
        .padding(.leading, 8)
    }
}

// MARK: - DropTarget
struct DropTarget: DropDelegate {
    let item: SidebarItem
    let groupIndex: Int?
    let store: SidebarStore

    func dropEntered(info: DropInfo) {
        guard let dragged = store.dragItem, dragged != item else { return }

        if let groupIndex = groupIndex,
           store.items.indices.contains(groupIndex),
           case .group(_, _, let children) = store.items[groupIndex],
           let idx = children.firstIndex(of: item) {
            store.dropTarget = (group: groupIndex, index: idx)
        } else if let idx = store.items.firstIndex(of: item) {
            store.dropTarget = (group: nil, index: idx)
        }
    }

    func performDrop(info: DropInfo) -> Bool {
        guard let dragged = store.dragItem,
              let target = store.dropTarget,
              dragged != item else { return false }

        // Remove dragged item
        if let idx = store.items.firstIndex(of: dragged) {
            store.items.remove(at: idx)
        } else {
            for i in store.items.indices {
                if case .group(let id, let name, var children) = store.items[i],
                   let childIdx = children.firstIndex(of: dragged) {
                    children.remove(at: childIdx)
                    store.items[i] = .group(id: id, name: name, children: children)
                    break
                }
            }
        }

        // Insert to new position
        if let group = target.group,
           store.items.indices.contains(group),
           case .group(let id, let name, var children) = store.items[group] {
            let insertIndex = min(target.index ?? children.count, children.count)
            children.insert(dragged, at: insertIndex)
            store.items[group] = .group(id: id, name: name, children: children)
        } else {
            let insertIndex = min(target.index ?? store.items.count, store.items.count)
            store.items.insert(dragged, at: insertIndex)
        }

        store.dragItem = nil
        store.dropTarget = nil
        return true
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        .init(operation: .move)
    }

    func dropExited(info: DropInfo) {
        store.dropTarget = nil
    }
}

// MARK: - EmptyGroupDropTarget
struct EmptyGroupDropTarget: DropDelegate {
    let groupIndex: Int
    let store: SidebarStore

    func performDrop(info: DropInfo) -> Bool {
        guard let dragged = store.dragItem else { return false }

        if let idx = store.items.firstIndex(of: dragged) {
            store.items.remove(at: idx)
        } else {
            for i in store.items.indices {
                if case .group(let id, let name, var children) = store.items[i],
                   let childIdx = children.firstIndex(of: dragged) {
                    children.remove(at: childIdx)
                    store.items[i] = .group(id: id, name: name, children: children)
                    break
                }
            }
        }

        if store.items.indices.contains(groupIndex),
           case .group(let id, let name, var children) = store.items[groupIndex] {
            children.append(dragged)
            store.items[groupIndex] = .group(id: id, name: name, children: children)
        }

        store.dragItem = nil
        return true
    }
}

// MARK: - DetailView
struct DetailView: View {
    @EnvironmentObject var store: SidebarStore

    var body: some View {
        VStack {
            if let selected = store.selected {
                Text("Selected: \(selected.title)")
                    .font(.title2)
                    .padding()
            } else {
                Text("Nothing selected")
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ContentView()
}
