import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';
  String phoneNumber = '';
  String name = ''; // حقل لإدخال الاسم
  String userType = 'مستخدم عادي'; // القيمة الافتراضية
  bool isLoading = false;

  /// التحقق من صحة نوع المستخدم
  bool isUserTypeValid(String userType) {
    return userType == 'طالب' || userType == 'شركة عقارات';
  }

  /// إنشاء الحساب
  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      try {
        // إنشاء حساب جديد في Firebase Auth
        UserCredential userCredential =
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        final user = userCredential.user;

        // إضافة بيانات المستخدم إلى Firestore
        if (user != null) {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'ownerId': user.uid,
            'name': name, // إضافة الاسم
            'email': email,
            'phoneNumber': phoneNumber,
            'userType': userType,
            'createdAt': FieldValue.serverTimestamp(),
          });

          // الانتقال إلى الشاشة التالية
          Navigator.pushReplacementNamed(context, '/apartments');
        }
      } on FirebaseAuthException catch (e) {
        // معالجة الأخطاء
        String errorMessage = "حدث خطأ أثناء إنشاء الحساب.";
        if (e.code == 'email-already-in-use') {
          errorMessage = "البريد الإلكتروني مستخدم بالفعل.";
        } else if (e.code == 'weak-password') {
          errorMessage = "كلمة المرور ضعيفة جدًا.";
        } else if (e.code == 'invalid-email') {
          errorMessage = "البريد الإلكتروني غير صالح.";
        }

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(errorMessage),
        ));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('حدث خطأ غير متوقع: $e'),
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
                "إنشاء حساب جديد",
                style: TextStyle(
                  fontSize: 28.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              SizedBox(height: 16.0),
              Text(
                "أهلاً بك! الرجاء ملء الحقول أدناه لإنشاء حساب جديد.",
                style: TextStyle(fontSize: 16.0, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32.0),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // حقل إدخال الاسم
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: "الاسم",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "يرجى إدخال الاسم";
                        }
                        return null;
                      },
                      onChanged: (value) {
                        name = value;
                      },
                    ),
                    SizedBox(height: 16.0),

                    // حقل إدخال البريد الإلكتروني
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

                    // حقل إدخال كلمة المرور
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
                          return "يجب أن تكون كلمة المرور مكونة من 6 أحرف على الأقل";
                        }
                        return null;
                      },
                      onChanged: (value) {
                        password = value;
                      },
                    ),
                    SizedBox(height: 16.0),

                    // حقل إدخال رقم الهاتف
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: "رقم الهاتف",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "يرجى إدخال رقم الهاتف";
                        }
                        return null;
                      },
                      onChanged: (value) {
                        phoneNumber = value;
                      },
                    ),
                    SizedBox(height: 16.0),

                    // اختيار نوع المستخدم
                    DropdownButtonFormField<String>(
                      value: userType,
                      onChanged: (value) {
                        setState(() {
                          userType = value!;
                        });
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "نوع المستخدم",
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'مستخدم عادي',
                          child: Text("مستخدم عادي"),
                        ),
                        DropdownMenuItem(
                          value: 'طالب',
                          child: Text("طالب"),
                        ),
                        DropdownMenuItem(
                          value: 'شركة عقارات',
                          child: Text("شركة عقارات"),
                        ),
                      ],
                    ),
                    SizedBox(height: 24.0),

                    // زر التسجيل
                    isLoading
                        ? CircularProgressIndicator()
                        : ElevatedButton(
                      onPressed: _signUp,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        minimumSize: Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: Text(
                        "إنشاء حساب",
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
                  Text("لديك حساب بالفعل؟"),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/');
                    },
                    child: Text(
                      "تسجيل الدخول",
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
