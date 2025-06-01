import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'main.dart';

class SplashScreen extends StatefulWidget {
  static const routeName = '/splash';
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/d.mp4')
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
        Future.delayed(_controller.value.duration, () {
          Navigator.pushNamedAndRemoveUntil(
            context,
            DomflixHomePage.routeName,
            (route) => false,
          );
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _controller.value.isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller), // <-- Qui viene mostrato il video
              )
            : CircularProgressIndicator(),
      ),
    );
  }
}