import 'package:flutter/material.dart';
import 'package:forex_journal_app/models/post.dart';
import 'package:forex_journal_app/main.dart';
import 'package:intl/intl.dart';

class TeachingScreen extends StatefulWidget {
  const TeachingScreen({super.key});

  @override
  State<TeachingScreen> createState() => _TeachingScreenState();
}

class _TeachingScreenState extends State<TeachingScreen> {
  bool _isAdmin = false; // Ești teacher?

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  // Verificăm rolul la pornirea ecranului
  void _checkRole() async {
    final isTeacher = await dbService.isTeacher();
    if (mounted) setState(() => _isAdmin = isTeacher);
  }

  void _showAddPostDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Postare Nouă (Teacher)'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Titlu', hintText: 'ex: Analiză Gold')),
              const SizedBox(height: 10),
              TextField(controller: contentController, maxLines: 6, decoration: const InputDecoration(labelText: 'Conținut', hintText: 'Scrie analiza aici...', border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Anulează')),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty && contentController.text.isNotEmpty) {
                final post = Post(
                  title: titleController.text,
                  content: contentController.text,
                  date: DateTime.now(),
                  authorName: 'Teacher', // Poți pune numele real din profil dacă vrei
                );
                await dbService.addPost(post);
                if (mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Publică'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // Butonul apare DOAR dacă ești admin
      floatingActionButton: _isAdmin 
          ? FloatingActionButton.extended(
              onPressed: _showAddPostDialog,
              backgroundColor: Colors.orange,
              label: const Text("Postare Nouă"),
              icon: const Icon(Icons.edit),
            )
          : null,
      
      body: StreamBuilder<List<Post>>(
        stream: dbService.getPostsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          final posts = snapshot.data ?? [];
          
          if (posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.school_outlined, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 10),
                  const Text("Nicio postare în Hub-ul Educațional.", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 15),
                elevation: 3,
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(post.title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black))),
                          if (_isAdmin)
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                              onPressed: () => dbService.deletePost(post.id),
                              tooltip: 'Șterge Postarea',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            )
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "${DateFormat('dd MMM HH:mm').format(post.date)} • ${post.authorName}",
                        style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 12),
                      ),
                      const Divider(),
                      const SizedBox(height: 5),
                      Text(post.content, style: TextStyle(fontSize: 15, height: 1.5, color: isDark ? Colors.white70 : Colors.black87)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}