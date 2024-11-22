import 'package:flutter/material.dart';
import '../models/member.dart';

class MemberProvider with ChangeNotifier {
  List<Member> _members = [];

  List<Member> get members => _members;

  void addMember(Member member) {
    _members.add(member);
    notifyListeners();
  }

  void updateMember(Member updatedMember) {
    int index = _members.indexWhere((m) => m.name == updatedMember.name);
    if (index != -1) {
      _members[index] = updatedMember;
      notifyListeners();
    }
  }

  void clearMembers() {
    _members.clear();
    notifyListeners();
  }
}
