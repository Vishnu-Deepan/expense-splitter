// import 'package:flutter/material.dart';
// import '../services/firebase_service.dart';
//
// class ViewMembersScreen extends StatelessWidget {
//   final FirebaseService firebaseService = FirebaseService();
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('View Members'),
//         centerTitle: true,
//       ),
//       body: StreamBuilder(
//         stream: firebaseService.getMembers(),
//         builder: (context, snapshot) {
//           // Show loading spinner while data is being fetched
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return Center(child: CircularProgressIndicator());
//           }
//
//           // Show an error message if something goes wrong
//           if (snapshot.hasError) {
//             return Center(
//               child: Text('Error: ${snapshot.error}'),
//             );
//           }
//
//           // If data is fetched successfully, process the members list
//           if (snapshot.hasData) {
//             final memberDocs =
//                 snapshot.data!.docs; // Access Firestore documents
//             if (memberDocs.isEmpty) {
//               return Center(
//                 child: Text(
//                   'No Members Added Yet!',
//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
//                 ),
//               );
//             }
//
//             // Display the list of members in a ListView
//             return ListView.builder(
//               itemCount: memberDocs.length,
//               itemBuilder: (context, index) {
//                 // Cast the Firestore document data to a Map
//                 final member = memberDocs[index].data() as Map<String, dynamic>;
//                 final memberName = member['name'] ?? 'Unnamed Member';
//
//                 return ListTile(
//                   title: Text(
//                     memberName,
//                     style: TextStyle(fontSize: 16),
//                   ),
//                   leading: CircleAvatar(
//                     child: Text(memberName[0].toUpperCase()),
//                   ),
//                 );
//               },
//             );
//           }
//
//           // Default fallback for unexpected states
//           return Center(
//             child: Text('Unexpected error occurred!'),
//           );
//         },
//       ),
//     );
//   }
// }
