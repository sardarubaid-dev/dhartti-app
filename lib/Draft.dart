import 'package:dhartti/PropertiesUploadedScreen.dart';
import 'package:dhartti/UserScreen/UserPageBottomNavbarAndAppBAr/Appbar.dart';
import 'package:flutter/material.dart';
class DraftUploadedScreen extends StatefulWidget {
  @override
  _DraftUploadedScreenState createState() => _DraftUploadedScreenState();
}

class _DraftUploadedScreenState extends State<DraftUploadedScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('My Properties'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Drafts'),
            Tab(text: 'Uploaded'),
          ],
        ),
      ),
      drawer: DrawerScreen(),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Drafts Tab
          DraftsTab(),
          // Uploaded Tab
          UploadedTab(),
        ],
      ),
    );
  }
}

class DraftsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.hourglass_empty,
            size: 80,
            color: Colors.grey,
          ),
          SizedBox(height: 20),
          Text(
            'No Drafts Available',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Navigate to Add Property Screen
              print('Add Property Button Clicked');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              'Add Property',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class UploadedTab extends StatefulWidget {
  @override
  _UploadedTabState createState() => _UploadedTabState();
}

class _UploadedTabState extends State<UploadedTab> with SingleTickerProviderStateMixin {
  late TabController _subTabController;

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _subTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Sub Tabs (Active, Pending, Rejected, Expired) - Each in its own box
        Padding(
          padding: const EdgeInsets.all(10), // Add padding around the tabs
          child: Row(
            children: [
              // Active Tab Box
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _subTabController.index = 0; // Switch to Active tab
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _subTabController.index == 0
                            ? Colors.green // Green border if selected
                            : Colors.grey.withOpacity(0.2), // Light border if not selected
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.symmetric(vertical: 15),
                    alignment: Alignment.center,
                    child: Text(
                      'Active (0)',
                      style: TextStyle(
                        color: _subTabController.index == 0
                            ? Colors.green // Green text if selected
                            : Colors.grey, // Grey text if not selected
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10), // Spacing between tabs
              // Pending Tab Box
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _subTabController.index = 1; // Switch to Pending tab
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _subTabController.index == 1
                            ? Colors.green // Green border if selected
                            : Colors.grey.withOpacity(0.2), // Light border if not selected
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.symmetric(vertical: 15),
                    alignment: Alignment.center,
                    child: Text(
                      'Pending (0)',
                      style: TextStyle(
                        color: _subTabController.index == 1
                            ? Colors.green // Green text if selected
                            : Colors.grey, // Grey text if not selected
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10), // Spacing between tabs
              // Rejected Tab Box
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _subTabController.index = 2; // Switch to Rejected tab
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _subTabController.index == 2
                            ? Colors.green // Green border if selected
                            : Colors.grey.withOpacity(0.2), // Light border if not selected
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.symmetric(vertical: 15),
                    alignment: Alignment.center,
                    child: Text(
                      'Rejected (0)',
                      style: TextStyle(
                        color: _subTabController.index == 2
                            ? Colors.green // Green text if selected
                            : Colors.grey, // Grey text if not selected
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10), // Spacing between tabs
              // Expired Tab Box
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _subTabController.index = 3; // Switch to Expired tab
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _subTabController.index == 3
                            ? Colors.green // Green border if selected
                            : Colors.grey.withOpacity(0.2), // Light border if not selected
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.symmetric(vertical: 15),
                    alignment: Alignment.center,
                    child: Text(
                      'Expired (0)',
                      style: TextStyle(
                        color: _subTabController.index == 3
                            ? Colors.green // Green text if selected
                            : Colors.grey, // Grey text if not selected
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Sub Tab Content
        Expanded(
          child: TabBarView(
            controller: _subTabController,
            children: [
              // Active Tab
              UnavailableContent(),
              // Pending Tab
              UnavailableContent(),
              // Rejected Tab
              UnavailableContent(),
              // Expired Tab
              UnavailableContent(),
            ],
          ),
        ),
      ],
    );
  }
}
class UnavailableContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.hourglass_empty,
            size: 80,
            color: Colors.grey,
          ),
          SizedBox(height: 20),
          Text(
            'No Data Available',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Navigate to Add Property Screen
              print('Add Property Button Clicked');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Text(
              'Add Property',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
