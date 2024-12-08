import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';
  bool isLoading = false;

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });
      try {
        // تسجيل الدخول
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        // التحقق من حالة ownerId وإضافته إذا لم يكن موجودًا
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          print("تم تسجيل الدخول بنجاح. UID: ${user.uid}");

          // جلب بيانات المستخدم من Firestore
          DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
          print("بيانات المستند: ${userDoc.exists}");  // تحقق من إذا كان المستند موجودًا

          if (userDoc.exists) {
            var userData = userDoc.data() as Map<String, dynamic>?;  // تحويل البيانات إلى Map
            print("بيانات المستخدم: $userData");  // تحقق من بيانات المستخدم

            // التأكد من أن المستخدم يحتوي على 'ownerId'
            if (userData != null && (userData['ownerId'] == null || userData['ownerId'] == '')) {
              print("ownerId فارغ أو غير موجود، سيتم إضافته");
              // إضافة ownerId للمستخدم إذا كان فارغًا
              await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                'ownerId': user.uid,  // إضافة ownerId هنا
                'displayName': user.displayName ?? 'اسم غير معروف',
                'email': user.email ?? 'بريد غير معروف',
              }, SetOptions(merge: true)); // استخدام merge لتجنب الكتابة فوق البيانات الموجودة
            }
          } else {
            print("المستند غير موجود، سيتم إنشاؤه");
            // إذا لم يوجد المستند، يمكنك إضافة البيانات
            await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
              'ownerId': user.uid,  // إضافة ownerId هنا
              'displayName': user.displayName ?? 'اسم غير معروف',
              'email': user.email ?? 'بريد غير معروف',
            });
          }
        }

        // تحديث رمز التحقق (Token) للمستخدم
        await _auth.currentUser!.getIdToken(true);

        // توجيه المستخدم إلى صفحة الشقق
        Navigator.pushReplacementNamed(context, '/apartments');
      } on FirebaseAuthException catch (e) {
        String errorMessage = "حدث خطأ أثناء تسجيل الدخول.";
        if (e.code == 'user-not-found') {
          errorMessage = "لم يتم العثور على مستخدم بهذا البريد الإلكتروني.";
        } else if (e.code == 'wrong-password') {
          errorMessage = "كلمة المرور غير صحيحة.";
        } else if (e.code == 'network-request-failed') {
          errorMessage = "تعذر الاتصال بالإنترنت. يرجى التحقق من الشبكة.";
        } else {
          errorMessage = "خطأ غير متوقع: ${e.message}";
        }

        // عرض رسالة خطأ للمستخدم
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(errorMessage),
        ));
      } catch (e) {
        print("حدث خطأ غير متوقع: $e");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("حدث خطأ غير متوقع أثناء محاولة تسجيل الدخول."),
        ));
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "تسجيل الدخول",
                style: TextStyle(
                  fontSize: 28.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              SizedBox(height: 16.0),
              Text(
                "أهلاً بعودتك! الرجاء تسجيل الدخول للوصول إلى حسابك.",
                style: TextStyle(fontSize: 16.0, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32.0),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: "البريد الإلكتروني",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "يرجى إدخال البريد الإلكتروني";
                        } else if (!RegExp(r'^[\w-]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value)) {
                          return "يرجى إدخال بريد إلكتروني صالح";
                        }
                        return null;
                      },
                      onChanged: (value) {
                        email = value;
                      },
                    ),
                    SizedBox(height: 16.0),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: "كلمة المرور",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "يرجى إدخال كلمة المرور";
                        } else if (value.length < 6) {
                          return "يجب أن تحتوي كلمة المرور على 6 أحرف على الأقل";
                        }
                        return null;
                      },
                      onChanged: (value) {
                        password = value;
                      },
                    ),
                    SizedBox(height: 24.0),
                    isLoading
                        ? CircularProgressIndicator()
                        : ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        minimumSize: Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: Text(
                        "دخول",
                        style: TextStyle(fontSize: 18.0),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("لا تملك حسابًا؟"),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/signup');
                    },
                    child: Text(
                      "إنشاء حساب",
                      style: TextStyle(color: Colors.blueAccent),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
