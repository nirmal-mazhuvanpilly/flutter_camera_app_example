import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
// import 'package:path/path.dart';

Future<void> main() async {
  // Ensure that plugin services are initialized so that 'availableCameras()'
  // can be called before 'runApp()'
  WidgetsFlutterBinding.ensureInitialized();

  // Obtain a list of the available cameras on the device.
  final cameras = await availableCameras();

  // Get a specific camera from the list of available cameras.
  final firstCamera = cameras.first;
  runApp(MyApp(
    camera: firstCamera,
  ));
}

class MyApp extends StatelessWidget {
  final CameraDescription camera;
  MyApp({
    this.camera,
  });
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData.dark(),
      home: HomePage(
        camera: camera,
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  final CameraDescription camera;
  HomePage({
    this.camera,
  });
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("HomePage"),
      ),
      body: Center(
        //Click to Open Camera
        child: RaisedButton(
          child: const Text("Open Camera"),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => TakePictureScreen(
                  camera: camera,
                ), // Pass the appropriate camera to the TakePictureScreen widget.
              ),
            );
          },
        ),
      ),
    );
  }
}

// A screen that allows users to take a picture using a given camera.
class TakePictureScreen extends StatefulWidget {
  final CameraDescription camera;
  TakePictureScreen({
    this.camera,
  });
  @override
  _TakePictureScreenState createState() => _TakePictureScreenState();
}

class _TakePictureScreenState extends State<TakePictureScreen> {
  CameraController _cameraController;
  Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    // To display the current output from the Camera,
    // create a CameraController.
    _cameraController = CameraController(
        // Get a specific camera from the list of available cameras.
        widget.camera,
        // Define the resolution to use.
        ResolutionPreset.high);

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _cameraController.initialize();
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // You must wait until the controller is initialized before displaying the
        // camera preview. Use a FutureBuilder to display a loading spinner until the
        // controller has finished initializing.
        title: const Text("Take a Picture"),
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // If the Future is complete, display the preview.
            //Used Stack to Use Focus Border in CameraPreview
            return Stack(
              children: <Widget>[
                CameraPreview(_cameraController),
                //Show Focus Border
                Center(
                  child: Container(
                    margin: const EdgeInsets.all(10),
                    height: 250,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      // color: Colors.yellow,
                      border: Border.all(
                        color: Colors.yellow,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            );
          } else {
            return Center(
              // Otherwise, display a loading indicator.
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        // Provide an onPressed callback.
        onPressed: () async {
          // Take the Picture in a try / catch block. If anything goes wrong,
          // catch the error.
          try {
            // Ensure that the camera is initialized.
            await _initializeControllerFuture;

            // Attempt to take a picture and get the file `image`
            // where it was saved.
            final image = await _cameraController.takePicture();

            // If the picture was taken, display it on a new screen.
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => DisplayPictureScreen(
                    // Pass the automatically generated path to
                    // the DisplayPictureScreen widget.
                    imagePath: image.path),
              ),
            );
          } catch (e) {
            // If an error occurs, log the error to the console.
            print(e);
          }
        },
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}

// A widget that displays the picture taken by the user.
class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;
  DisplayPictureScreen({
    @required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // The image is stored as a file on the device. Use the `Image.file`
        // constructor with the given path to display the image.
        title: const Text("Display the Picture"),
      ),
      body: Column(
        children: <Widget>[
          Container(
            margin: const EdgeInsets.all(50),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: Image.file(
                File(imagePath),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
