import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class StripePaymentScreen extends StatefulWidget {
  const StripePaymentScreen({super.key});

  @override
  _StripePaymentScreenState createState() => _StripePaymentScreenState();
}

class _StripePaymentScreenState extends State<StripePaymentScreen> {
  Map<String, dynamic>? paymentIntent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stripe Payment'),
      ),
      body: Center(
        child: ElevatedButton(
          child: const Text('Make Payment'),
          onPressed: () async {
            await makePayment();
          },
        ),
      ),
    );
  }

  Future<void> makePayment() async {
    try {
      // STEP 1: Create Payment Intent
      paymentIntent = await createPaymentIntent('100', 'USD');

      var gpay = const PaymentSheetGooglePay(
          merchantCountryCode: "US",
          currencyCode: "USD",
          testEnv: true);

      // STEP 2: Initialize Payment Sheet
      await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
              paymentIntentClientSecret: paymentIntent!['client_secret'], // Gotten from payment intent
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
    }
  }

  Future<void> displayPaymentSheet() async {
    try {
      await Stripe.instance.presentPaymentSheet().then((value) {
        debugPrint("Payment Successfully");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment Successful')),
          );
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
            content: Text("Cancelled: ${e.error.localizedMessage}"),
          ),
        );
      }
    } catch (e) {
      debugPrint('$e');
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
