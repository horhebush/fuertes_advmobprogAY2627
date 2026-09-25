// The signed-in user, as returned by the auth endpoint or by Firestore.
class User {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String gender;
  final String image;
  final String accessToken;
  final String refreshToken;

  // ENHANCEMENT 2: only a Firebase account carries these three.
  final String uid;
  final int age;
  final String contactNo;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.image,
    required this.accessToken,
    required this.refreshToken,
    this.uid = '',
    this.age = 0,
    this.contactNo = '',
  });

  // Builds a user from the login response, from Firestore, or from preferences.
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      gender: json['gender'] ?? '',
      image: json['image'] ?? '',
      // The API calls it accessToken; older responses only had token.
      accessToken: json['accessToken'] ?? json['token'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
      uid: json['uid'] ?? '',
      age: json['age'] ?? 0,
      contactNo: json['contactNo'] ?? '',
    );
  }

  // Turns the user back into JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'gender': gender,
      'image': image,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'uid': uid,
      'age': age,
      'contactNo': contactNo,
    };
  }

  // The fields that belong in the Firestore profile document. uid is stored
  // as well as being the document id, because the chat list reads it back.
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'username': username,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'age': age,
      'contactNo': contactNo,
    };
  }

  // First and last name together, for the profile header.
  String get fullName => '$firstName $lastName'.trim();
}
