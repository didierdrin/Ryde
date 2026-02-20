import 'package:ryde_rw/firestore_stub.dart';
import 'package:ryde_rw/models/wallet_transaction_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ryde_rw/shared/shared_states.dart';

class WalletTransactionsService {
  static final fireStore = FirebaseFirestore.instance;
  static final collection = fireStore.collection('walletTransactions');
  static final CollectionReference walletCollection = FirebaseFirestore.instance
      .collection('walletTransactions');

  static Future createWalletTransaction(
    Map<String, dynamic> walletTransaction,
  ) async {
    try {
      await collection.add(walletTransaction);
    } catch (e) {
      throw Exception("Failed to create wallet transaction: $e");
    }
  }

  static final myTransactions = StreamProvider<List<WalletTransaction>>((ref) {
    final user = ref.watch(userProvider)!;
    return collection.where('user', isEqualTo: user.id).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return WalletTransaction.fromMap(data);
      }).toList();
    });
  });

  static Future<void> updateUserWallet(String user, int amount) async {
    try {
      final userDoc = await fireStore.collection('users').doc(user).get();
      final userWallet = (userDoc.data()!['walletBalance'] ?? 0) as int;
      await fireStore.collection('users').doc(user).update({
        'walletBalance': userWallet + amount,
      });
    } catch (e) {
      throw Exception("Failed to update user wallet: $e");
    }
  }
}

