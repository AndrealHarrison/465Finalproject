import SwiftUI

struct ContentView: View {
    @StateObject var itemManager = ItemManager()
    @State var showModal = false
    
    
    var body: some View {
        NavigationView {
            List {
                ForEach(itemManager.items) { item in
                    NavigationLink(destination: ItemDetailView(item: item)) {
                        VStack(alignment: .leading) {
                            Text(item.id!)
                                .font(.headline)
                            Text(item.name)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Items")
            .onAppear {
                itemManager.fetchItems()
            }
            .navigationBarItems(trailing: Button(action: {
                showModal = true
            }, label: {
                Image(systemName: "plus")
            }))
            .sheet(isPresented: $showModal, content: {
                AddItemView()
                    .environmentObject(itemManager)
            })
            .refreshable {
                itemManager.fetchItems()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct Items: Codable {
    var results: [Item]
}

struct Item: Codable, Identifiable {
    var id: String?
    var name: String
}

class ItemManager: ObservableObject {
    @Published var items = [Item]()
    var selectedItem: Item?
    
    func fetchItems() {
        URLSession.shared.dataTask(with: URL(string: "https://f83itp0fhd.execute-api.us-west-2.amazonaws.com/dev/User_func1")!) { data, response, error in
            guard let data = data else {
                print("Error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            do {
                let decodedData = try JSONDecoder().decode([Item].self, from: data)
                DispatchQueue.main.async {
                    self.items = decodedData
                }
            } catch let error {
                print("Error: \(error.localizedDescription)")
            }
        }
        .resume()
    }
    
    func addItem(item: Item, completion: @escaping (Result<Item, Error>) -> Void) {
        guard let url = URL(string: "https://f83itp0fhd.execute-api.us-west-2.amazonaws.com/dev/User_func1") else {
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        guard let jsonData = try? JSONEncoder().encode(item) else {
                    print("Error: Trying to convert model to JSON data")
                    return
                }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                completion(.failure(error ?? NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unknown error"])))
                return
            }
            
            do {
                let item = try JSONDecoder().decode(Item.self, from: data)
                completion(.success(item))
            } catch let error {
                completion(.failure(error))
            }
        }
        .resume() // Start the data task
    }
    
    func deleteItem(id: String) {
            guard let url = URL(string: "https://f83itp0fhd.execute-api.us-west-2.amazonaws.com/dev/User_func1/\(id)") else {
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print(error)
                    return
                }
                
                guard let data = data else {
                    return
                }
                
                do {
                    let result = try JSONDecoder().decode(DeleteResponse.self, from: data)
                    if result.success {
                        DispatchQueue.main.async {
                            if let index = self.items.firstIndex(where: { $0.id == id }) {
                                self.items.remove(at: index)
                            }
                        }
                    }
                } catch let error {
                    print(error)
                }
            }.resume()
        }
    
    func updateItem(id: String, name: String) {
            guard let url = URL(string: "https://f83itp0fhd.execute-api.us-west-2.amazonaws.com/dev/User_func1/\(id)") else {
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            
            let params: [String: Any] = [
                "id": id,
                "name": name
            ]
            
            request.httpBody = try? JSONSerialization.data(withJSONObject: params, options: [])
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print(error)
                    return
                }
                
                guard let data = data else {
                    return
                }
                
                do {
                    let item = try JSONDecoder().decode(Item.self, from: data)
                    DispatchQueue.main.async {
                        if let index = self.items.firstIndex(where: { $0.id == item.id }) {
                            self.items[index] = item
                        }
                    }
                } catch let error {
                    print(error)
                }
            }.resume()
        }
    
    struct DeleteResponse: Decodable {
        let success: Bool
    }

}

struct ItemDetailView: View {
    @StateObject var itemManager = ItemManager()
    @Environment(\.presentationMode) var presentationMode
    @State var editMode = false
    @State var item: Item
    
    var body: some View {
        VStack(alignment: .leading) {
            if editMode {
                TextField("Title", text: $item.name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                TextField("Body", text: $item.name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            } else {
                Text("Title: \(item.id!)")
                    .font(.headline)
                Text("Body: \(item.name)")
                    .foregroundColor(.secondary)
                
            }
            Spacer()
            HStack {
                if editMode {
                    Button("Save") {
                        itemManager.updateItem(id: item.id!, name: item.name)
                        editMode.toggle()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                } else {
                    Button("Edit") {
                        editMode.toggle()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.yellow)
                }
                Button("Delete Item") {
                    itemManager.deleteItem(id: item.id!)
                    presentationMode.wrappedValue.dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
        }
        .padding()
        .navigationBarTitle(Text(item.name), displayMode: .inline)
    }
}

struct AddItemView: View {
    @EnvironmentObject var itemManager: ItemManager
    @State private var title = ""
    @State private var itemBody = ""
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Item")) {
                    TextField("item", text: $title)
                }
                Section(header: Text("ID")) {
                    TextEditor(text: $itemBody)
                }
            }
            .navigationBarTitle("New Item", displayMode: .inline)
            .navigationBarItems(trailing:
                Button(action: {
                    let item = Item(id: title, name: itemBody)
                itemManager.addItem(item: item) {_ in}
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Add")
                }
                .disabled(title.isEmpty || itemBody.isEmpty)
            )
        }
    }
}
