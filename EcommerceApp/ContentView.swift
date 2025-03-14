//
//  ContentView.swift
//  EcommerceApp
//
//  Created by Mohar on 13/03/25.
//

import SwiftUI

struct Product: Identifiable, Codable {
    let id = UUID()
    let name: String
    let price: Double
    let image: String
}

struct Order: Identifiable, Codable {
    let id = UUID()
    let products: [Product]
    let totalPrice: Double
    let date: Date
}

class CartManager: ObservableObject {
    @Published var cartItems: [Product] = [] {
        didSet {
            saveCart()
        }
    }
    @Published var orderHistory: [Order] = [] {
        didSet {
            saveOrders()
        }
    }
    
    init() {
        loadCart()
        loadOrders()
    }
    
    func addToCart(product: Product) {
        cartItems.append(product)
    }
    
    func removeFromCart(index: Int) {
        cartItems.remove(at: index)
    }
    
    func checkout() {
        let totalPrice = cartItems.reduce(0) { $0 + $1.price }
        let newOrder = Order(products: cartItems, totalPrice: totalPrice, date: Date())
        orderHistory.append(newOrder)
        cartItems.removeAll()
        saveCart()
        saveOrders()
        
        
    }
    
    private func saveCart() {
        if let encoded = try? JSONEncoder().encode(cartItems) {
            UserDefaults.standard.set(encoded, forKey: "cart")
        }
    }
    
    private func loadCart() {
        if let data = UserDefaults.standard.data(forKey: "cart"),
           let decoded = try? JSONDecoder().decode([Product].self, from: data) {
            cartItems = decoded
        }
    }
    
    private func saveOrders() {
        if let encoded = try? JSONEncoder().encode(orderHistory) {
            UserDefaults.standard.set(encoded, forKey: "orders")
        }
    }
    
    private func loadOrders() {
        if let data = UserDefaults.standard.data(forKey: "orders"),
           let decoded = try? JSONDecoder().decode([Order].self, from: data) {
            orderHistory = decoded
        }
    }
}

struct ContentView: View {
    
    let products = [
        Product(name: "iPhone 14", price: 999.99, image: "iphone"),
        Product(name: "MacBook Pro", price: 1999.99, image: "macbook"),
        Product(name: "AirPods Pro", price: 399.99, image: "airpods")
    ]
    
    @StateObject var cartManager = CartManager()
    
    var body: some View {
        NavigationView {
            List(products) { product in
                NavigationLink(destination: ProductDetailView(product: product, cartManager: cartManager)) {
                    HStack {
                        Image(product.image)
                            .resizable()
                            .frame(width: 50, height: 50)
                        VStack(alignment: .leading) {
                            Text(product.name).font(.headline)
                            Text("$\(product.price, specifier: "%.2f")")
                        }
                        Spacer()
                        Button(action: {
                            cartManager.addToCart(product: product)
                        }) {
                            Text("Add to Cart")
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                }
            }
            .navigationTitle("Products")
            .toolbar {
                HStack {
                    NavigationLink(destination: OrderHistoryView(cartManager: cartManager)) {
                        Text("📜 Orders")
                    }
                    NavigationLink(destination: CartView(cartManager: cartManager)) {
                        Text("🛒 Cart (\(cartManager.cartItems.count))")
                    }
                }
            }
        }
    }
}

struct ProductDetailView: View {
    let product: Product
    @ObservedObject var cartManager: CartManager
    
    var body: some View {
        VStack(spacing: 20) {
            Image(product.image)
                .resizable()
                .frame(width: 200, height: 200)
            Text(product.name).font(.largeTitle)
            Text("$\(product.price, specifier: "%.2f")").font(.title)
            Button("Add to Cart") {
                cartManager.addToCart(product: product)
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
    }
}

struct CartView: View {
    @ObservedObject var cartManager: CartManager
    @State var showsAlert = false
    var body: some View {
        VStack {
            List {
                ForEach(cartManager.cartItems.indices, id: \ .self) { index in
                    let product = cartManager.cartItems[index]
                    HStack {
                        Text(product.name)
                        Spacer()
                        Text("$\(product.price, specifier: "%.2f")")
                        Button("❌") {
                            cartManager.removeFromCart(index: index)
                        }
                    }
                }
            }
            .navigationTitle("Cart")
            Button("Checkout") {
                cartManager.checkout()
                self.showsAlert.toggle()
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)
            .alert(isPresented: self.$showsAlert) {
                       Alert(title: Text("Checkout successful, order saved to My orders!"))
                   }
        }
    }
}

struct OrderHistoryView: View {
    @ObservedObject var cartManager: CartManager
    
    var body: some View {
        VStack {
            List(cartManager.orderHistory) { order in
                VStack(alignment: .leading) {
                    Text("Order Date: \(order.date, formatter: DateFormatter.shortDate)").font(.headline)
                    Text("Total: $\(order.totalPrice, specifier: "%.2f")")
                    ForEach(order.products) { product in
                        Text("- \(product.name)")
                    }
                }
            }
            .navigationTitle("Order History")
        }
    }
}

extension DateFormatter {
    static var shortDate: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }
}

@main
struct ECommerceApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

#Preview {
    
    ContentView()
}
