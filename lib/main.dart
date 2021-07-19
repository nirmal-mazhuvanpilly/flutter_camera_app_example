import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:image/image.dart' as img;
import 'package:native_device_orientation/native_device_orientation.dart';

//Flutter Camera App with Crop Functionality Programmatically
void main() {
  // Ensure that plugin services are initialized so that 'availableCameras'
  // can be called before 'runApp()'
  WidgetsFlutterBinding.ensureInitialized();

  //Setting PreferredOrientation to Portrait
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitDown,
    DeviceOrientation.portraitUp,
  ]);
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

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File imgFile;

  Widget showImage(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Center(
          child: Container(
            height: MediaQuery.of(context).size.height * .30,
            width: MediaQuery.of(context).size.width * .95,
            decoration: imgFile != null
                ? BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    image: DecorationImage(
                        image: FileImage(imgFile), fit: BoxFit.fill),
                  )
                : BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
          ),
        ),
        imgFile == null
            ? Center(
                child: Icon(
                  Icons.camera_alt_outlined,
                  size: 40,
                  color: Colors.black54,
                ),
              )
            : Container(),
      ],
    );
  }

  void gotoTakePicture(BuildContext context) async {
    await Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => TakePicture(),
      ),
    )
        .then((value) {
      print("Crop File in Home Screen");
      if (value != null) {
        setState(() {
          imgFile = value;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Camera HomePage"),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          showImage(context),
          SizedBox(height: 25),
          Center(
            //Click to Open Camera
            child: RaisedButton(
              child: const Text("Open Camera"),
              onPressed: () {
                gotoTakePicture(context);
              },
            ),
          ),
        ],
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
class TakePicture extends StatefulWidget {
  @override
  _TakePictureState createState() => _TakePictureState();
}

class _TakePictureState extends State<TakePicture> {
  bool useSensor = true;

  var _availableCamera;

  var _selectedCamera;

  CameraController _cameraController;

  Future<void> _initializeControllerFuture;

  GlobalKey _focusKeyValue = GlobalKey();

  GlobalKey _pointerKeyValue = GlobalKey();

  double dx = 0;
  double dy = 0;
  double dh = 0;
  double dw = 0;

  double dxPointer = 0;
  double dyPointer = 0;
  double dhPointer = 0;
  double dwPointer = 0;

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

  _afterLayout(_) {
    _getPositionofFocusBorder();
    _getPositionofPointer();
  }

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

  Future<File> cropImage(BuildContext context, String imagePath) async {
    // To get Screen size
    final screenSize = MediaQuery.of(context).size;
    // To get Status bar size
    final statusBarSize = MediaQuery.of(context).padding.top;

    // To get Screen width & height
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    print("Screen Height : $screenHeight");
    print("Screen Width : $screenWidth");
    print("Status Bar Height : $statusBarSize");

    // To get Image properties
    ImageProperties properties =
        await FlutterNativeImage.getImageProperties(imagePath);

    // To get Image height and width
    int imageWidth = properties.width;
    int imageHeight = properties.height;

    print("imageWidth:$imageWidth");
    print("imageHeight:$imageHeight");

    // To get xOffset,yOffset,widthOffset,heightOffset
    int xOffset = ((dx * imageWidth) / screenWidth).round();
    int yOffset = ((dy * imageHeight) / screenHeight).round();
    int widthOffset = ((dw * imageWidth) / screenWidth).round();
    int heightOffset = ((dh * imageHeight) / screenHeight).round();

    print(
        "xOffset:$xOffset , yOffset:$yOffset , widthOffset:$widthOffset , heightOffset:$heightOffset  ");

    final croppedImage = await FlutterNativeImage.cropImage(
      imagePath,
      xOffset,
      yOffset,
      widthOffset,
      heightOffset,
    );

    return croppedImage;
  }

  Future<File> fixRotationRight(String imagePath) async {
    print("fixExifRotattionRight");
    final originalFile = File(imagePath);
    List<int> imageBytes = await originalFile.readAsBytes();

    final originalImage = img.decodeImage(imageBytes);

    final height = originalImage.height;
    final width = originalImage.width;

    print("Original Image Height : $height");
    print("Original Image Width : $width");

    // Let's check for the image size
    // This will be true also for upside-down photos but it's ok for me
    if (height >= width) {
      // I'm interested in portrait photos so
      // I'll just return here
      return originalFile;
    }

    img.Image fixedImage;

    if (height <= width) {
      print("Block Right");
      fixedImage = img.copyRotate(originalImage, 90);
      print("Fixed Image Height : ${fixedImage.height}");
      print("Fixed Image Width : ${fixedImage.width}");
    }

    // Here you can select whether you'd like to save it as png
    // or jpg with some compression
    // I choose jpg with 100% quality
    final fixedFile =
        await originalFile.writeAsBytes(img.encodeJpg(fixedImage));

    return fixedFile;
  }

  Future<File> fixRotationLeft(String imagePath) async {
    print("fixExifRotattionLeft");
    final originalFile = File(imagePath);
    List<int> imageBytes = await originalFile.readAsBytes();

    final originalImage = img.decodeImage(imageBytes);

    final height = originalImage.height;
    final width = originalImage.width;

    print("Original Image Height : $height");
    print("Original Image Width : $width");

    // Let's check for the image size
    // This will be true also for upside-down photos but it's ok for me
    if (height >= width) {
      // I'm interested in portrait photos so
      // I'll just return here
      return originalFile;
    }

    img.Image fixedImage;

    if (height <= width) {
      // rotate

      print("Block Left");
      fixedImage = img.copyRotate(originalImage, -90);
      print("Fixed Image Height : ${fixedImage.height}");
      print("Fixed Image Width : ${fixedImage.width}");
    }

    // Here you can select whether you'd like to save it as png
    // or jpg with some compression
    // I choose jpg with 100% quality
    final fixedFile =
        await originalFile.writeAsBytes(img.encodeJpg(fixedImage));

    return fixedFile;
  }

  @override
  void initState() {
    SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.top]);
    SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.bottom]);

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

  Widget closeCameraBtn(BuildContext context) {
    return CircleAvatar(
      backgroundColor: Colors.white,
      child: IconButton(
          icon: Icon(Icons.close),
          onPressed: () {
            Navigator.of(context).pop();
          }),
    );
  }

  Widget toggleCameraBtn(BuildContext context) {
    return CircleAvatar(
      backgroundColor: Colors.white,
      child: IconButton(
        icon: Icon(Icons.linked_camera_rounded),
        onPressed: _toggleCamera,
      ),
    );
  }

  // Navigate to Display Picture
  void gotoDisplayPicture(File cropFile) async {
    await Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => DisplayPictureScreen(
          // Pass the automatically generated path to
          // the DisplayPictureScreen widget.
          // pass the cropped file path
          image: cropFile,
        ),
      ),
    )
        .then((value) {
      print("Crop File in Take Picture : $value");
      if (value != null) {
        Navigator.of(context).pop(cropFile);
      }
    });
  }

  Widget takeImageBtn(BuildContext context) {
    return CircleAvatar(
      backgroundColor: Colors.white,
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

            // To get Image properties
            ImageProperties properties =
                await FlutterNativeImage.getImageProperties(image.path);
            // Print Image height and width
            print("Image Properties Height : ${properties.height}");
            print("Image Properties Width : ${properties.width}");

            File cropFile;
            File fixImageRight;
            File fixImageLeft;

            if (properties.height >= properties.width) {
              cropFile = await cropImage(context, image.path);
            } else {
              // Rotate Image Right
              fixImageRight = await fixRotationRight(image.path);

              //Crop Image
              cropFile = await cropImage(context, fixImageRight.path);

              // Rotate Image Left
              fixImageLeft = await fixRotationLeft(cropFile.path);

              cropFile = fixImageLeft;
            }

            // If the picture was taken and cropped, display it on a new screen.
            gotoDisplayPicture(cropFile);
          } catch (e) {
            // If an error occurs, log the error to the console.
            print(e);
          }
        },
      ),
    );
  }

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
              borderRadius: BorderRadius.circular(10),
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
                return Container(
                  height: double.infinity,
                  width: double.infinity,
                  child: CameraPreview(_cameraController),
                );
              } else {
                return Container();
              }
            },
          ),
          focusBorder(context),
          //Use flutter native_device_orientation package to use NativeDeviceOrientationReader
          NativeDeviceOrientationReader(
            // Set useSensor to true to get NativeDeviceOrientation
            useSensor: useSensor,
            builder: (context) {
              final orientation =
                  NativeDeviceOrientationReader.orientation(context);
              print('Received new orientation: $orientation');

              if (orientation == NativeDeviceOrientation.portraitUp) {
                return Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(25.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        closeCameraBtn(context),
                        takeImageBtn(context),
                        toggleCameraBtn(context),
                      ],
                    ),
                  ),
                );
              } else {
                return Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(25.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        closeCameraBtn(context),
                        toggleCameraBtn(context),
                      ],
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

// A widget that displays the picture taken by the user.
class DisplayPictureScreen extends StatelessWidget {
  final File image;

  DisplayPictureScreen({
    @required this.image,
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: MediaQuery.of(context).size.height * .30,
                  width: MediaQuery.of(context).size.width * .95,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    image: DecorationImage(
                      image: FileImage(image),
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                //Button to Retake Camera
                //Close current context
                CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                SizedBox(width: 25),
                CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: Icon(Icons.check),
                    onPressed: () {
                      Navigator.of(context).pop(image);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
