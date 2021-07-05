import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:image/image.dart' as img;
import 'package:exif/exif.dart';

void main() {
  // Ensure that plugin services are initialized so that 'availableCameras'
  // can be called before 'runApp()'
  WidgetsFlutterBinding.ensureInitialized();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Camera HomePage"),
      ),
      body: Center(
        //Click to Open Camera
        child: RaisedButton(
          child: const Text("Open Camera"),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => TakePictureScreen(),
              ),
            );
          },
        ),
      ),
    );
  }
}

//Custom Class to get Centre Point
class Origin extends CustomPainter {
  final BuildContext context;
  Origin({
    this.context,
  });
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = Colors.red[400]
      ..strokeWidth = 2
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    Offset center = Offset(size.width / 2, size.height / 2);
    // print(center);

    canvas.drawCircle(center, 5, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

// A screen that allows users to take a picture.
class TakePictureScreen extends StatefulWidget {
  @override
  _TakePictureScreenState createState() => _TakePictureScreenState();
}

class _TakePictureScreenState extends State<TakePictureScreen> {
  var _availableCamera;
  var _selectedCamera;
  CameraController _cameraController;
  Future<void> _initializeControllerFuture;
  GlobalKey _focusKeyValue = GlobalKey();
  GlobalKey _pointerKeyValue = GlobalKey();

  static double dx = 0;
  static double dy = 0;
  static double dh = 0;
  static double dw = 0;

  static double dxPointer = 0;
  static double dyPointer = 0;
  static double dhPointer = 0;
  static double dwPointer = 0;

  //Function to get Camera
  _getCamera() async {
    // Get the list of available cameras.
    _availableCamera = await availableCameras();
    print(availableCameras);

    // Get a specific camera from the list of available cameras.
    _selectedCamera = _availableCamera.first;
    print(_selectedCamera);

    // To display the current output from the Camera,
    // create a CameraController.
    _cameraController = CameraController(
        // Get a specific camera from the list of available cameras.
        _selectedCamera,
        // Define the resolution to use.
        ResolutionPreset.high);

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _cameraController.initialize();
  }

  // Function to get Position of Focus Border
  _getPositionofFocusBorder() {
    RenderBox box = _focusKeyValue.currentContext.findRenderObject();
    Offset position = box.localToGlobal(Offset.zero);
    double x = position.dx;
    double y = position.dy;

    setState(() {
      dx = x;
      dy = y;
      dh = box.size.height;
      dw = box.size.width;
      print("FocusBorder Details == dx : $dx , dy : $dy , dh : $dh , dw : $dw");
    });
  }

  // Function to get Position of Pointer
  _getPositionofPointer() {
    RenderBox box = _pointerKeyValue.currentContext.findRenderObject();
    Offset position = box.localToGlobal(Offset.zero);
    double x = position.dx;
    double y = position.dy;

    setState(() {
      dxPointer = x;
      dyPointer = y;
      dhPointer = box.size.height;
      dwPointer = box.size.width;
      print(
          "Pointer Details == dx : $dxPointer , dy : $dyPointer , dh : $dhPointer , dw : $dwPointer");
    });
  }

  //This function will call in addPostFrameCallback
  _afterLayout(_) {
    _getPositionofFocusBorder();
    _getPositionofPointer();
  }

  // Function to toggle Camera
  _toggleCamera() {
    setState(() {
      _selectedCamera = _selectedCamera == _availableCamera.first
          ? _availableCamera.elementAt(1)
          : _availableCamera.elementAt(0);
      _cameraController =
          CameraController(_selectedCamera, ResolutionPreset.high);
      _initializeControllerFuture = _cameraController.initialize();
    });
  }

  //Function to Rotate File
  // Using exif & image package
  Future<File> fixExifRotation(String imagePath) async {
    final originalFile = File(imagePath);
    List<int> imageBytes = await originalFile.readAsBytes();

    final originalImage = img.decodeImage(imageBytes);

    final height = originalImage.height;
    final width = originalImage.width;

    // Let's check for the image size
    if (height >= width) {
      // I'm interested in portrait photos so
      // I'll just return here
      print("Original image Height : ${originalImage.height}");
      print("Original image Width : ${originalImage.width}");
      return originalFile;
    }

    // We'll use the exif package to read exif data
    // This is map of several exif properties
    // Let's check 'Image Orientation'
    final exifData = await readExifFromBytes(imageBytes);

    img.Image fixedImage;

    if (height < width) {
      // rotate
      if (exifData['Image Orientation'].printable.contains('Horizontal')) {
        fixedImage = img.copyRotate(originalImage, 90);
        print("Block 1");
        print("Fixed image Height : ${fixedImage.height}");
        print("Fixed image Width : ${fixedImage.width}");
      } else if (exifData['Image Orientation'].printable.contains('180')) {
        fixedImage = img.copyRotate(originalImage, -90);
        print("Block 2");
        print("Fixed image Height : ${fixedImage.height}");
        print("Fixed image Width : ${fixedImage.width}");
      } else {
        fixedImage = img.copyRotate(originalImage, 90);
        print("Block 3");
        print("Fixed image Height : ${fixedImage.height}");
        print("Fixed image Width : ${fixedImage.width}");
      }
    }

    // Here you can select whether you'd like to save it as png
    // or jpg with some compression
    // I choose jpg with 100% quality
    final fixedFile =
        await originalFile.writeAsBytes(img.encodeJpg(fixedImage));

    return fixedFile;
  }

  // Function to Crop Image
  // Using flutter native image package
  Future<File> cropImage(BuildContext context, String imagePath) async {
    final screenSize = MediaQuery.of(context).size;

    // final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    int heightOffset = screenHeight.round();
    // int widthOffset = screenWidth.round();

    ImageProperties properties =
        await FlutterNativeImage.getImageProperties(imagePath);

    int imageWidth = properties.width;
    int imageHeight = properties.height;

    print("imageWidth:$imageWidth");
    print("imageHeight:$imageHeight");

    final dxCrop = dx.round();
    final dyCrop = dy.round();
    final dhCrop = dh.round();
    final dwCrop = dw.round();
    print("dxCrop:$dxCrop , dyCrop:$dyCrop , dhCrop:$dhCrop , dwCrop:$dwCrop");

    final croppedImage = await FlutterNativeImage.cropImage(
      imagePath,
      dxCrop,
      dyCrop + 150,
      (imageWidth * .95).toInt(),
      dwCrop,
    );

    print(
        "Exact conversion : x:$dxCrop , y:${dyCrop + 150} , w:${(imageWidth * .95).toInt()} , h:$dwCrop");

    return croppedImage;
  }

  @override
  void initState() {
    // Flutter Framework has a convenient API to request a callback method to be executed once a frame rendering is complete.
    // This method is:
    // WidgetsBinding.instance.addPostFrameCallback.
    WidgetsBinding.instance.addPostFrameCallback(_afterLayout);
    super.initState();

    //Function to get Camera
    _getCamera();
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _cameraController.dispose();
    super.dispose();
  }

  // Toggle Camera Button Widget
  Widget toggleCameraBtn(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: IconButton(
        icon: Icon(Icons.switch_camera_rounded),
        onPressed: _toggleCamera,
      ),
    );
  }

  // Take Image Button Widget
  Widget takeImageBtn(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: IconButton(
        icon: Icon(Icons.camera_alt),
        onPressed: () async {
          // Take the Picture in a try / catch block. If anything goes wrong,
          // catch the error.
          try {
            // Ensure that the camera is initialized.
            await _initializeControllerFuture;

            // Attempt to take a picture and get the file `image`
            // where it was saved.
            final image = await _cameraController.takePicture();
            print(image.path);

            // Rotate Image
            final rotateFile = await fixExifRotation(image.path);

            //Crop Image
            final cropFile = await cropImage(context, rotateFile.path);

            // If the picture was taken and cropped, display it on a new screen.
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => DisplayPictureScreen(
                  // Pass the automatically generated path to
                  // the DisplayPictureScreen widget.
                  // pass the cropped file path
                  imagePath: cropFile.path,
                ),
              ),
            );
          } catch (e) {
            // If an error occurs, log the error to the console.
            print(e);
          }
        },
      ),
    );
  }

  // Focus Border Widget
  Widget focusBorder(BuildContext context) {
    return Stack(
      children: <Widget>[
        Center(
          child: Container(
            key: _focusKeyValue,
            height: MediaQuery.of(context).size.height * .30,
            width: MediaQuery.of(context).size.width * .95,
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

        //To Display origin of center in Red Color
        CustomPaint(
          key: _pointerKeyValue,
          painter: Origin(context: context),
          child: Container(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                // If the Future is complete, display the preview.
                //Used Stack to Use Focus Border in CameraPreview
                return CameraPreview(_cameraController);
              } else {
                return Center(
                  // Otherwise, display a loading indicator.
                  child: CupertinoActivityIndicator(),
                );
              }
            },
          ),
          focusBorder(context),
          toggleCameraBtn(context),
          takeImageBtn(context),
        ],
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
        // The image is stored as a file on the device. Use the 'Image.file'
        // constructor with the given path to display the image.
        title: const Text("Display the Picture"),
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Flexible(
              flex: 1,
              child: Container(
                // color: Colors.white,
                height: 250,
                width: double.infinity,
                margin: const EdgeInsets.all(10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.file(
                    File(imagePath),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            SizedBox(height: 25),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                //Button to Retake Camera
                //Close current context
                IconButton(
                  icon: Icon(Icons.camera_alt),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                Text("Retake"),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
