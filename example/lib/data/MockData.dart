import 'package:blankets_and_wines_example/features/Stockist/Stockist.dart';


class MockOrdersData {
  static List<StockistOrder> getOrders() {
    return [
      StockistOrder(
        barName: "Blankets & Wines",
        id: 1,
        orderNumber: "ORD-001234",
        timestamp: DateTime.now().subtract(Duration(minutes: 5)),
        cashierName: "Sarah M.",
        total: 23.50,
        status: OrderStatus.pending,
        items: [
          OrderItem(
            name: "Corona Extra",
            quantity: 2,
            price: 11.00,
            category: "Beer",
            emoji: "🍺",
          ),
          OrderItem(
            name: "Mojito",
            quantity: 1,
            price: 9.00,
            category: "Cocktails",
            emoji: "🍹",
          ),
          OrderItem(
            name: "Coca Cola",
            quantity: 1,
            price: 3.50,
            category: "Non-Alcoholic",
            emoji: "🥤",
          ),
        ],
      ),
      StockistOrder(
        orderNumber: "ORD-73002",
        timestamp: DateTime.now().subtract(Duration(minutes: 8)),
        cashierName: "Mike R.",
        total: 45.00,
        status: OrderStatus.preparing,
        items: [
          OrderItem(
            name: "Whiskey",
            quantity: 2,
            price: 16.00,
            category: "Spirits",
            emoji: "🥃",
          ),
          OrderItem(
            name: "Cabernet Sauvignon",
            quantity: 1,
            price: 12.00,
            category: "Wine",
            emoji: "🍷",
          ),
          OrderItem(
            name: "Old Fashioned",
            quantity: 1,
            price: 11.00,
            category: "Cocktails",
            emoji: "🥃",
          ),
          OrderItem(
            name: "Water",
            quantity: 3,
            price: 6.00,
            category: "Non-Alcoholic",
            emoji: "💧",
          ),
        ],
      ),
      StockistOrder(
        orderNumber: "ORD-001236",
        timestamp: DateTime.now().subtract(Duration(minutes: 12)),
        cashierName: "Lisa K.",
        total: 18.50,
        status: OrderStatus.ready,
        items: [
          OrderItem(
            name: "Margarita",
            quantity: 1,
            price: 9.50,
            category: "Cocktails",
            emoji: "🍹",
          ),
          OrderItem(
            name: "Orange Juice",
            quantity: 2,
            price: 7.00,
            category: "Non-Alcoholic",
            emoji: "🧃",
          ),
          OrderItem(
            name: "Heineken",
            quantity: 1,
            price: 6.00,
            category: "Beer",
            emoji: "🍺",
          ),
        ],
      ),
    ];
  }
}