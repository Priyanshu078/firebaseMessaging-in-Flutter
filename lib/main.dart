import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:notifications/pushNotification.dart';
import 'package:overlay_support/overlay_support.dart';

import 'notification_badge.dart';

Future firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OverlaySupport(
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const MyHomePage(title: 'Notify'),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late int totalNotifications;
  late final FirebaseMessaging firebaseMessaging;
  PushNotification? notificationInfo;

  @override
  void initState() {
    super.initState();
    checkForInitialMessage();
    registerNotification();
    totalNotifications = 0;

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      PushNotification notification = PushNotification(
          title: message.notification?.title, body: message.notification?.body);

      setState(() {
        totalNotifications++;
        notificationInfo = notification;
      });
    });
  }

  void checkForInitialMessage() async {
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      PushNotification notification = PushNotification(
          title: initialMessage.notification?.title,
          body: initialMessage.notification?.body,
          dataTitle: initialMessage.data["title"],
          dataBody: initialMessage.data["body"]);

      setState(() {
        notificationInfo = notification;
        totalNotifications++;
      });
    }
  }

  void registerNotification() async {
    firebaseMessaging = FirebaseMessaging.instance;

    FirebaseMessaging.onBackgroundMessage(
        (message) => firebaseMessagingBackgroundHandler(message));

    NotificationSettings settings = await firebaseMessaging.requestPermission(
        alert: true, badge: true, provisional: false, sound: true);

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print("User granted permission");

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        PushNotification notification = PushNotification(
          title: message.notification?.title,
          body: message.notification?.body,
          dataTitle: message.data["title"],
          dataBody: message.data["data"],
        );

        setState(() {
          notificationInfo = notification;
          totalNotifications++;
        });

        if (notificationInfo != null) {
          showSimpleNotification(Text(notificationInfo!.title!),
              leading:
                  NotificationBadge(totalNotifications: totalNotifications),
              subtitle: Text(notificationInfo!.body!),
              background: Colors.deepPurpleAccent,
              duration: const Duration(seconds: 3));
        }
      });
    } else {
      print("permission denied");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'App for capturing Firebase Push Notifications',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 16.0),
            NotificationBadge(totalNotifications: totalNotifications),
            const SizedBox(height: 16.0),
            notificationInfo != null
                ? Card(
                    color: Colors.grey,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            "title : ${notificationInfo!.dataTitle} ${notificationInfo!.title!}",
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            "body : ${notificationInfo!.dataBody} ${notificationInfo!.body!}",
                            style: const TextStyle(fontSize: 20),
                          ),
                        )
                      ],
                    ),
                  )
                : Container()
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
