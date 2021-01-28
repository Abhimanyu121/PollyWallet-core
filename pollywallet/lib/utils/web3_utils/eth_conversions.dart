import 'dart:math';

class EthConversions {
  static double weiToEth(BigInt amount, int decimal) {
    if (decimal == null) {
      double db = amount / BigInt.from(10).pow(18);
      return double.parse(db.toStringAsFixed(2));
    } else {
      double db = amount / BigInt.from(10).pow(decimal);
      return double.parse(db.toStringAsFixed(2));
    }
  }

  static BigInt weiToGwei(BigInt amount) {
    var db = amount / BigInt.from(10).pow(9);
    var bi = BigInt.from(db.toInt());
    return bi;
  }

  static BigInt ethToWei(String amount) {
    double db = double.parse(amount) * pow(10, 4);
    int it = db.toInt();
    BigInt bi = BigInt.from(it) * BigInt.from(10).pow(14);
    return bi;
  }
}
