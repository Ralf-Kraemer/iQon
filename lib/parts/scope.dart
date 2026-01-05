import 'package:flutter/material.dart';
import 'package:toot_ui/helper.dart';

class Scope extends StatefulWidget {
  const Scope({super.key});

  @override
  State<Scope> createState() => _ScopeState();
}

class _ScopeState extends State<Scope> {
  final Helper helper = Helper.get();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: <Widget>[
        SliverAppBar(
          pinned: true,
          floating: false,
          snap: false,
          elevation: 0,
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Row(
            children: const [
              Icon(Icons.dashboard_outlined, size: 18),
              SizedBox(width: 6),
              Text(
                'Scope',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          centerTitle: false,
          toolbarHeight: 44, // small / compact
        ),

        SliverList(
          delegate: SliverChildListDelegate(
            const [
              ExpansionTile(
                title: Text('👥 People'),
                subtitle: Text('Trailing expansion arrow icon'),
                children: <Widget>[
                  ListTile(title: Text('This is tile number 1')),
                ],
              ),

              ExpansionTile(
                title: Text('📈 #Trends'),
                subtitle: Text('Trailing expansion arrow icon'),
                children: <Widget>[
                  ListTile(title: Text('This is tile number 2')),
                ],
              ),

              ExpansionTile(
                title: Text('🔔 Alerts'),
                initiallyExpanded: true,
                subtitle: Text('Trailing expansion arrow icon'),
                children: <Widget>[
                  Card(
                    child: ListTile(
                      leading: Icon(Icons.notifications_sharp),
                      title: Text('Notification 1'),
                      subtitle: Text('This is a notification'),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: Icon(Icons.notifications_sharp),
                      title: Text('Notification 2'),
                      subtitle: Text('This is a notification'),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: Icon(Icons.notifications_sharp),
                      title: Text('Notification 3'),
                      subtitle: Text('This is a notification'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
