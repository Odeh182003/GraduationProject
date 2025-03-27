import 'package:flutter/material.dart';
class Createpostsofficial extends StatefulWidget {
  const Createpostsofficial({super.key});

  @override
  _Createpostsofficial createState() => _Createpostsofficial();
}

class _Createpostsofficial extends State<Createpostsofficial> {
  // Controllers for form fields
  TextEditingController nameController = TextEditingController();
  TextEditingController universityIdController = TextEditingController();
  TextEditingController commentController = TextEditingController();
  bool isPrivate = false; // Checkbox state

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: Text("Create New Post"),
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.green,
      elevation: 0,
      ),
      
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
             

              SizedBox(height: 10),

              // Name field
              Text("Name *"),
              SizedBox(height: 5),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: "Enter your full name",
                  border: OutlineInputBorder(),
                ),
              ),

              SizedBox(height: 10),

              // University ID field
              Text("University ID *"),
              SizedBox(height: 5),
              TextField(
                controller: universityIdController,
                decoration: InputDecoration(
                  hintText: "Enter your ID",
                  border: OutlineInputBorder(),
                ),
              ),

              SizedBox(height: 10),

              // Post Comment field
              Text("Post Comment *"),
              SizedBox(height: 5),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Enter what your comment",
                  border: OutlineInputBorder(),
                ),
              ),

              SizedBox(height: 10),

              // Post Media (Attachment Icon)
              Text("Post Media *"),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.attachment),
                    onPressed: () {},
                  ),
                  Text("Attach file"),
                ],
              ),

              // Checkbox for private post
              Row(
                children: [
                  Checkbox(
                    value: isPrivate,
                    onChanged: (bool? value) {
                      setState(() {
                        isPrivate = value!;
                      });
                    },
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Is Private?"),
                      Text(
                        "Check the box if your post is private",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: 10),

              // Submit button
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    // Handle form submission
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  ),
                  child: Text("Submit", style: TextStyle(color: Colors.white)),
                ),
              ),

              Spacer(),

              // Bottom Navigation Bar
              BottomNavigationBarUI(),
            ],
          ),
        ),
      ),
    );
  }
}

// Bottom Navigation Bar Widget
class BottomNavigationBarUI extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.explore, color: Colors.black),
              Text("Explore", style: TextStyle(color: Colors.black)),
            ],
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.message, color: Colors.black),
              Text("Messaging", style: TextStyle(color: Colors.black)),
            ],
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person, color: Colors.black),
              Text("Profile", style: TextStyle(color: Colors.black)),
            ],
          ),
        ],
      ),
    );
  }
}