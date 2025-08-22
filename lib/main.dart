import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  await Hive.initFlutter();
  await Hive.openBox('tasksBox');
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DoDoing',
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _box = Hive.box('tasksBox');
  final _input = TextEditingController();
  final Map<int, GlobalKey> _taskKeys = {}; // keys for positioning emojis

  final List<String> bloomEmojis = [
    '🌸', '🌺', '🌷', '🌹', '🪻', '✨', '💫', '🌈',
    '💕', '💞', '💓', '💗', '🩷', '🌟'
  ];

  String get _today {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  List<Map> _getTasks() {
    final tasks = _box.get(_today, defaultValue: []);
    return List<Map>.from(tasks);
  }

  void _saveTasks(List<Map> tasks) {
    _box.put(_today, tasks);
  }

  void _addTask() {
    final text = _input.text.trim();
    if (text.isEmpty) return;

    final tasks = _getTasks();
    tasks.add({
      'id': DateTime.now().millisecondsSinceEpoch,
      'title': text,
      'isDone': false
    });

    _saveTasks(tasks);
    _input.clear();
    setState(() {});
  }

  void _toggleDone(int id, BuildContext context) {
    final key = _taskKeys[id];
    if (key == null) return;

    RenderBox box = key.currentContext!.findRenderObject() as RenderBox;
    Offset pos = box.localToGlobal(Offset(box.size.width / 2, box.size.height / 2));

    final tasks = _getTasks();
    for (var t in tasks) {
      if (t['id'] == id) {
        t['isDone'] = !(t['isDone'] as bool);
        if (t['isDone'] == true) {
          _showEmojiBloom(context, pos);
        }
      }
    }
    _saveTasks(tasks);
    setState(() {});
  }

  void _deleteTask(int id) {
    final tasks = _getTasks();
    tasks.removeWhere((t) => t['id'] == id);
    _saveTasks(tasks);
    setState(() {});
  }

  void _showEmojiBloom(BuildContext context, Offset position) {
    final emoji = bloomEmojis[Random().nextInt(bloomEmojis.length)];
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => Positioned(
        left: position.dx - 20,
        top: position.dy - 20,
        child: _EmojiBloom(
          emoji: emoji,
          onComplete: () => entry.remove(),
        ),
      ),
    );
    Overlay.of(context)?.insert(entry);
  }

  @override
  Widget build(BuildContext context) {
    final tasks = _getTasks();
    final todo = tasks.where((t) => !t['isDone']).toList();
    final done = tasks.where((t) => t['isDone']).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('DoDoing', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.pinkAccent,
        elevation: 2,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.pink[50]!, Colors.pink[100]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Input Row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    decoration: InputDecoration(
                      hintText: 'Add a task...',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _addTask(),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _addTask,
                  style: ElevatedButton.styleFrom(
                    shape: CircleBorder(),
                    padding: EdgeInsets.all(14),
                    backgroundColor: Colors.pinkAccent,
                  ),
                  child: Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  // To Do Section
                  if (todo.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('To Do', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        ...todo.map((t) {
                          return Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            elevation: 2,
                            margin: EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              key: _taskKeys[t['id']] ??= GlobalKey(),
                              title: Text(t['title'], style: TextStyle(fontSize: 16)),
                              leading: Checkbox(
                                value: t['isDone'],
                                onChanged: (_) => _toggleDone(t['id'], context),
                                activeColor: Colors.pinkAccent,
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.delete, color: Colors.grey[700]),
                                onPressed: () => _deleteTask(t['id']),
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  // Done Section
                  if (done.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 16),
                        Text('Done Today', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        ...done.map((t) {
                          return Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            elevation: 1,
                            margin: EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              key: _taskKeys[t['id']] ??= GlobalKey(),
                              title: Text(
                                t['title'],
                                style: TextStyle(
                                  fontSize: 16,
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey[700],
                                ),
                              ),
                              leading: Checkbox(
                                value: t['isDone'],
                                onChanged: (_) {},
                                activeColor: Colors.pinkAccent,
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.delete, color: Colors.grey[700]),
                                onPressed: () => _deleteTask(t['id']),
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  if (tasks.isEmpty)
                    Center(child: Padding(
                      padding: EdgeInsets.only(top: 50),
                      child: Text('No tasks yet!', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                    )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= _EmojiBloom Widget =================
class _EmojiBloom extends StatefulWidget {
  final String emoji;
  final VoidCallback onComplete;

  const _EmojiBloom({required this.emoji, required this.onComplete});

  @override
  State<_EmojiBloom> createState() => _EmojiBloomState();
}

class _EmojiBloomState extends State<_EmojiBloom> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Duration(milliseconds: 800));
    _animation = Tween<double>(begin: 0, end: -80).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onComplete();
        }
      });
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: Opacity(
            opacity: 1 - _controller.value,
            child: Text(widget.emoji, style: TextStyle(fontSize: 30)),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
