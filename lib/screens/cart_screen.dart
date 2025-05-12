import 'package:flutter/material.dart';
import 'package:happy_farm/models/cart_model.dart';
import 'package:happy_farm/service/cart_service.dart';

class CartScreen extends StatefulWidget {
  final String userId;

  const CartScreen({super.key, required this.userId});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late Future<List<CartItem>> cartFuture;

  @override
  void initState() {
    super.initState();
    cartFuture = CartService.fetchCart(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title:Center(child:const Text("My Cart")) ,
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), // popup/back arrow
          onPressed: () {
            Navigator.pop(context); // or your custom back logic
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ClipOval(
              child: Image.asset(
                'assets/images/logo.png', // Replace with your logo path
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<CartItem>>(
        future: cartFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Cart is empty"));
          }

          final cartItems = snapshot.data!;
          final total = cartItems.fold(0, (sum, item) => sum + item.subTotal);

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    ...cartItems.map((item) => _buildCartItem(item)).toList(),
                    const SizedBox(height: 16),
                    _buildCouponField(),
                    const SizedBox(height: 12),
                    _buildAddressSection(),
                    const SizedBox(height: 12),
                    _buildPaymentDetails(cartItems.length, total),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
              _buildBottomBar(total),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCartItem(CartItem item) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.product.images.first,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Rs.${item.product.prices[0].actualPrice.toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                const Icon(Icons.delete_outline, color: Colors.red,),
                const SizedBox(height: 10),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.deepOrange,),
                      onPressed: () {},
                    ),
                    Text(item.quantity.toString()),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline,color: Colors.green,),
                      onPressed: () {},
                    ),
                  ],
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCouponField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          Text("Avail Offer (Coupon Code)", style: TextStyle(fontSize: 15)),
          Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
    );
  }

  Widget _buildAddressSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Chip(
            label: Text("Home Address"),
            backgroundColor: Colors.grey,
            labelStyle: TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 8),
          const Text("Delivery to Faizan Khan, 344022"),
          const Text("Opp State Bank Of India, Asotara..."),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.green.shade800,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Text("Change"),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPaymentDetails(int itemCount, int total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Payment Details",
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _paymentRow("Price ($itemCount items)", total),
          _paymentRow("Discount", 0),
          _paymentRow("Delivery Charges", "FREE"),
          const Divider(),
          _paymentRow("Total Amount", total, isBold: true),
          const SizedBox(height: 6),
          const Text("You saved 120 on this order",
              style: TextStyle(color: Colors.green)),
        ],
      ),
    );
  }

  Widget _paymentRow(String title, dynamic value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(
            value is String ? value : "Rs.$value",
            style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(int total) {
    return Positioned(
      bottom: 0,
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            RichText(
              text: TextSpan(
                text: "Rs.$total\n",
                style: const TextStyle(
                    fontSize: 16,
                    color: Colors.red,
                    fontWeight: FontWeight.bold),
                children: const [
                  TextSpan(
                    text: "View price details",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade800,
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("Proceed"),
            )
          ],
        ),
      ),
    );
  }
}
