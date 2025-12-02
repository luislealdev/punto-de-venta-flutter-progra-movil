import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../services/auth_service.dart';
import '../../../services/subscription_service.dart';
import '../../../models/subscription_dto.dart';

class StripePaymentScreen extends StatefulWidget {
  const StripePaymentScreen({super.key});

  @override
  _StripePaymentScreenState createState() => _StripePaymentScreenState();
}

class _StripePaymentScreenState extends State<StripePaymentScreen> {
  Map<String, dynamic>? paymentIntent;
  final AuthService _authService = AuthService();
  final SubscriptionService _subscriptionService = SubscriptionService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suscripción Premium'),
      ),
      body: Center(
        child: _isLoading 
          ? const CircularProgressIndicator()
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, size: 100, color: Colors.amber),
                const SizedBox(height: 20),
                const Text(
                  'Plan Premium',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  '\$199.00 / mes',
                  style: TextStyle(fontSize: 20, color: Colors.green),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                  child: const Text('Suscribirse Ahora', style: TextStyle(fontSize: 18)),
                  onPressed: () async {
                    await makePayment();
                  },
                ),
              ],
            ),
      ),
    );
  }

  Future<void> makePayment() async {
    try {
      setState(() => _isLoading = true);
      // STEP 1: Create Payment Intent
      // 19900 cents = $199.00
      paymentIntent = await createPaymentIntent('19900', 'MXN');

      var gpay = const PaymentSheetGooglePay(
          merchantCountryCode: "MX",
          currencyCode: "MXN",
          testEnv: true);

      // STEP 2: Initialize Payment Sheet
      await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
              paymentIntentClientSecret: paymentIntent!['client_secret'],
              style: ThemeMode.light,
              merchantDisplayName: 'Punto de Venta',
              googlePay: gpay));

      // STEP 3: Display Payment sheet
      await displayPaymentSheet();
    } catch (err) {
      debugPrint('Error making payment: $err');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $err')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> displayPaymentSheet() async {
    try {
      await Stripe.instance.presentPaymentSheet().then((value) async {
        debugPrint("Payment Successfully");
        
        // Activar suscripción
        await _activateSubscription();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Pago exitoso! Suscripción activada.')),
          );
          // Navegar al home y remover todas las rutas anteriores para forzar recarga
          Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
        }
        paymentIntent = null;
      }).onError((error, stackTrace) {
        debugPrint('Error presenting payment sheet: $error');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $error')),
          );
        }
      });
    } on StripeException catch (e) {
      debugPrint('Stripe Error: $e');
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            content: Text("Cancelado: ${e.error.localizedMessage}"),
          ),
        );
      }
    } catch (e) {
      debugPrint('$e');
    }
  }

  Future<void> _activateSubscription() async {
    try {
      final companyId = _authService.currentCompanyId;
      if (companyId == null) throw Exception("No company ID found");

      final now = DateTime.now();
      final endDate = now.add(const Duration(days: 30));

      final subscription = SubscriptionDTO(
        companyId: companyId,
        plan: 'premium',
        monthlyPrice: 199.00,
        startDate: now,
        endDate: endDate,
        status: 'active',
        paymentMethod: 'stripe',
        createdAt: now,
        updatedAt: now,
        // Valores por defecto del DTO para premium
        maxStores: 5,
        maxUsers: 10,
        maxProducts: 1000,
        hasAdvancedReports: true,
        hasMultiStore: true,
      );

      await _subscriptionService.createSubscription(subscription);
    } catch (e) {
      debugPrint("Error activating subscription: $e");
      // Aquí deberíamos manejar el error, tal vez reintentar o contactar soporte
      // ya que el pago sí se realizó.
    }
  }

  createPaymentIntent(String amount, String currency) async {
    try {
      Map<String, dynamic> body = {
        'amount': amount,
        'currency': currency,
      };

      var response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer ${dotenv.env['STRIPE_SECRET_KEY_TEST']}',
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: body,
      );
      return json.decode(response.body);
    } catch (err) {
      throw Exception(err.toString());
    }
  }
}
