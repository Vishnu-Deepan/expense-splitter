class Member {
  final String id;
  final String name;

  Member({required this.id, required this.name});

  factory Member.fromFirestore(Map<String, dynamic> data, String id) {
    return Member(id: id, name: data['name']);
  }
}
