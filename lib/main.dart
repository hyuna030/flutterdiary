import 'package:flutter/material.dart';
import 'dart:math';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MaterialApp(
    home: MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<String> data = [
    '미래의 나에게 한마디',
    '오늘 먹은것',
    '행복',
    '사랑',
    '잠',
    '꽃',
    '구름',
    '하늘',
    '강아지',
    '고양이',
    '빵'
  ];
  String randomData = '';
  DateTime currentDate = DateTime.now();
  DateTime? selectedDate;
  bool showImage = false;

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final TextEditingController diaryController = TextEditingController();

  String previousDiary = '';

  @override
  void initState() {
    super.initState();
    selectedDate = currentDate;
    showImage = true;
    updateRandomData();
    fetchPreviousDiary();
  }

  void updateRandomData() {
    final random = Random();
    setState(() {
      randomData = data[random.nextInt(data.length)];
    });
  }

  List<Widget> generateCalendarDays() {
    int year = currentDate.year;
    int month = currentDate.month;

    int numberOfDays = DateTime(year, month + 1, 0).day;

    List<Widget> days = [];

    for (int i = 1; i <= numberOfDays; i++) {
      days.add(GestureDetector(
        onTap: () {
          setState(() {
            selectedDate = DateTime(year, month, i);
            showImage = true;
            fetchPreviousDiary();
          });
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: Text(
                i.toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.normal,
                  color: Colors.white,
                  fontSize: 25,
                ),
              ),
            ),
            if (selectedDate != null && selectedDate!.day == i && showImage)
              Positioned(
                top: -4,
                right: -6,
                child: Image.asset(
                  'assets/haru_white.png',
                  width: 65,
                  height: 65,
                ),
              ),
          ],
        ),
      ));
    }

    return days;
  }

  void fetchPreviousDiary() {
    if (selectedDate != null) {
      final String selectedDateStr = selectedDate!.toString();
      firestore
          .collection('diaries')
          .doc(selectedDateStr)
          .get()
          .then((snapshot) {
        if (snapshot.exists) {
          setState(() {
            previousDiary = snapshot.data()!['diary'] ?? '';
          });
        } else {
          setState(() {
            previousDiary = '';
          });
        }
      }).catchError((error) {
        setState(() {
          previousDiary = '';
        });
        print('이전 일기 가져오기 중 오류가 발생했습니다: $error');
      });
    }
  }

  void saveDiary(String diary) {
    if (selectedDate != null) {
      CollectionReference diaries = firestore.collection('diaries');
      Map<String, dynamic> diaryData = {
        'date': Timestamp.fromDate(selectedDate!),
        'diary': diary,
      };
      diaries.doc(selectedDate!.toString()).set(diaryData).then((value) {
        print('일기가 성공적으로 저장되었습니다.');
        setState(() {
          previousDiary = diary;
        });
      }).catchError((error) => print('일기 저장 중 오류가 발생했습니다: $error'));
    }
  }

  void navigateToDiaryPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryPage(
          previousDiary: previousDiary,
          onSave: saveDiary,
        ),
      ),
    ).then((_) {
      fetchPreviousDiary();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        fontFamily: 'Pretendard',
      ),
      home: Scaffold(
        backgroundColor: const Color(0xFFB4CFDF),
        body: Column(children: [
          const SizedBox(
            height: 44,
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(10, 6, 15, 50),
            height: 110,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/home.png',
                      width: 50,
                      height: 50,
                    ),
                    const SizedBox(
                      width: 285,
                    ),
                    GestureDetector(
                      onTap: () {
                        updateRandomData();
                      },
                      child: Image.asset(
                        'assets/refresh.png',
                        width: 50,
                        height: 50,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Text(
            '오늘의 주제',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 30,
            ),
          ),
          Text(
            randomData,
            style: const TextStyle(
              fontWeight: FontWeight.normal,
              color: Colors.white,
              fontSize: 25,
            ),
          ),
          const SizedBox(
            height: 50,
          ),
          Container(
            height: 40,
            alignment: Alignment.center,
            child: Text(
              '${currentDate.year}년 ${currentDate.month}월',
              style: const TextStyle(
                fontWeight: FontWeight.normal,
                color: Colors.white,
                fontSize: 30,
              ),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: GridView.count(
                crossAxisCount: 7,
                padding: EdgeInsets.zero,
                children: generateCalendarDays(),
              ),
            ),
          ),
          if (selectedDate != null && showImage)
            Text(
              '${selectedDate!.month}월 ${selectedDate!.day}일',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 30,
              ),
            ),
          TextButton(
            onPressed: () {
              navigateToDiaryPage(context);
            },
            child: const Text(
              '일기 쓰기',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 30,
              ),
            ),
          ),
          const SizedBox(
            height: 120,
          ),
        ]),
      ),
    );
  }
}

class DiaryPage extends StatefulWidget {
  final String previousDiary;
  final Function(String) onSave;

  const DiaryPage({
    Key? key,
    required this.previousDiary,
    required this.onSave,
  }) : super(key: key);

  @override
  _DiaryPageState createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  final TextEditingController controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller.text = widget.previousDiary;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
          0xFFB4CFDF), // Match the background color of the main page
      appBar: AppBar(
        // Remove the app bar
        toolbarHeight: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '이전 일기',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18.0,
                color: Colors.white, // Set the text color to white
              ),
            ),
            const SizedBox(height: 10.0),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.0),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    offset: Offset(0, 2),
                    blurRadius: 6.0,
                  ),
                ],
              ),
              child: Text(
                widget.previousDiary,
                style: const TextStyle(fontSize: 16.0),
              ),
            ),
            const SizedBox(height: 20.0),
            const Text(
              '새로운 일기 작성',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18.0,
                color: Colors.white, // Set the text color to white
              ),
            ),
            const SizedBox(height: 10.0),
            TextField(
              controller: controller,
              maxLines: 10,
              style: const TextStyle(
                  color: Colors.white), // Set the text color to white
              decoration: const InputDecoration(
                hintText: '일기를 입력하세요',
                hintStyle: TextStyle(
                    color: Colors.white70), // Set the hint text color to white
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: Colors
                          .white), // Set the border color to white when focused
                ),
              ),
            ),
            const SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () {
                String diary = controller.text;
                widget.onSave(diary);
                Navigator.pop(context);
              },
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );
  }
}
