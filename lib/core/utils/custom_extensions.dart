
import 'package:cloud_firestore/cloud_firestore.dart';

extension CustomGetters on DocumentSnapshot {
  int getInt(key) {
    return data().toString().contains(key) ? get(key) : 0;
  }

  String getString(key) {
    return data().toString().contains(key) ? get(key) : '';
  }

  List<String> getList(key) {
    return data().toString().contains(key)
        ? (get(key) as List).map((e) => e as String).toList()
        : [];
  }

  Timestamp getTimeStamp(key) {
    return data().toString().contains(key) ? get(key) : Timestamp(0, 0);
  }

  DateTime getDateFromTs(key) {
    return data().toString().contains(key)
        ? (get(key) as Timestamp).toDate()
        : DateTime(0);
  }
}

extension JsonGetters on Map<String, dynamic> {
  int getInt(key) {
    return toString().contains(key) ? this[key] : 0;
  }

  String getString(key) {
    return toString().contains(key) ? this[key] : '';
  }

  bool getBool(key) {
    return toString().contains(key) ? this[key] : false;
  }
}

extension FirestoreDocumentExtension<T> on DocumentReference<T> {
  Future<DocumentSnapshot<T>> getCacheFirst() async {
    try {
      var ds = await get(const GetOptions(source: Source.cache));
      if (!ds.exists) return get(const GetOptions(source: Source.server));
      return ds;
    } catch (_) {
      return get(const GetOptions(source: Source.server));
    }
  }
}

extension FirestoreQueryExtension<T> on Query<T> {
  Future<QuerySnapshot<T>> getCacheFirst() async {
    try {
      var qs = await get(const GetOptions(source: Source.cache));
      if (qs.docs.isEmpty) return get(const GetOptions(source: Source.server));
      return qs;
    } catch (_) {
      return get(const GetOptions(source: Source.server));
    }
  }
}
