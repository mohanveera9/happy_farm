import 'package:flutter/material.dart';
import 'package:happy_farm/models/cart_model.dart';
import 'package:happy_farm/utils/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:happy_farm/service/order_service.dart';
import 'package:happy_farm/service/user_service.dart';
class CheckoutScreen extends StatefulWidget {
  final List<CartItem> cartItems;
  final int totalAmount;
  const CheckoutScreen({
    Key? key,
    required this.cartItems,
    required this.totalAmount,
  }) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _orderService = OrderService();
  final _authService=UserService();

  late Razorpay _razorpay;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _address1Controller = TextEditingController();
  final TextEditingController _address2Controller = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _zipController = TextEditingController();

  String? userId;
  String? token;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _loadUserData();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId');

    if (userId != null) {
      final data = await _authService.fetchUserDetails(userId!);
      if (data != null) {
        setState(() {
          _nameController.text = data['name'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _emailController.text = data['email'] ?? '';
        });
      }
    }
  }

    void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final verified = await _orderService.verifyPayment(
      razorpayOrderId: response.orderId!,
      razorpayPaymentId: response.paymentId!,
      razorpaySignature: response.signature!,
      orderId: _orderIdFromBackend!,
    );

    if (verified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order placed successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment verification failed')),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment failed: ${response.message}')),
    );
  }
  void _handleExternalWallet(ExternalWalletResponse response) {
    print("External Wallet: ${response.walletName}");
  }

  String? _orderIdFromBackend;

 Future<void> _submitForm() async {
    final fullAddress =
        '${_address1Controller.text}, ${_address2Controller.text}, ${_cityController.text}, ${_stateController.text}, ${_countryController.text}';

    final orderResponse = await _orderService.createOrder(
      name: _nameController.text,
      phoneNumber: _phoneController.text,
      email: _emailController.text,
      address: fullAddress,
      pincode: _zipController.text,
    );

    if (orderResponse != null) {
      final orderData = orderResponse['data'];
      _orderIdFromBackend = orderData['orderId'];

      final options = {
        'key': 'rzp_live_DJA2rvcCmZFLh3',
        'amount': orderData['amount'],
        'currency': orderData['currency'] ?? 'INR',
        'name': 'E-Bharat',
        'description': 'Payment for your order',
        'order_id': orderData['order_id'],
        'prefill': {
          'name': _nameController.text,
          'email': _emailController.text,
          'contact': _phoneController.text,
        },
        'theme': {'color': '#007B4F'}
      };

      _razorpay.open(options);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create order')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("Checkout"),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isWide = constraints.maxWidth > 700;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildAddressForm()),
                      const SizedBox(width: 24),
                      SizedBox(width: 350, child: _buildOrderSummary()),
                    ],
                  )
                : Column(
                    children: [
                      _buildAddressForm(),
                      const SizedBox(height: 24),
                      _buildOrderSummary(),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _buildAddressForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "BILLING DETAILS",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildFormTextField(
                  controller: _nameController,
                  label: "Full Name *",
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFormTextField(
                  controller: _countryController,
                  label: "Country *",
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Required' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildFormTextField(
            controller: _address1Controller,
            label: "Street address *\nHouse number and street name",
            validator: (val) => val == null || val.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          _buildFormTextField(
            controller: _address2Controller,
            label: "Apartment, suite, unit, etc. (optional)",
          ),
          const SizedBox(height: 12),
          _buildFormTextField(
            controller: _cityController,
            label: "Town / City *",
            validator: (val) => val == null || val.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          _buildFormTextField(
            controller: _stateController,
            label: "State / County *",
            validator: (val) => val == null || val.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          _buildFormTextField(
            controller: _zipController,
            label: "Postcode / ZIP *",
            validator: (val) => val == null || val.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildFormTextField(
                  controller: _phoneController,
                  label: "Phone Number",
                  keyboardType: TextInputType.phone,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFormTextField(
                  controller: _emailController,
                  label: "Email Address",
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Required';
                    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                    return emailRegex.hasMatch(val)
                        ? null
                        : 'Enter a valid email';
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    final cartItems = widget.cartItems;
    final totalAmount = widget.totalAmount;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "YOUR ORDER",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            ...cartItems.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(item.product.name)),
                    Text(
                        '₹${item.product.prices[0].actualPrice} x ${item.quantity}'),
                  ],
                ),
              );
            }).toList(),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '₹$totalAmount',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _submitForm();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Please fill all required fields')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'PLACE ORDER',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: _inputDecoration(label),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      filled: true,
      fillColor: Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    );
  }
}
