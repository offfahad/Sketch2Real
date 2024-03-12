import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:human_face_generator/src/common_widgets/dialogs/dialog_helper.dart';
import 'package:human_face_generator/src/constants/server_url.dart';
import 'package:human_face_generator/src/features/liveSketching/models/custom_painter.dart';
import 'package:human_face_generator/src/features/liveSketching/models/drawing_point.dart';
import 'package:human_face_generator/src/constants/colors.dart';
import 'package:human_face_generator/src/features/authentication/screens/profile/profile_screen.dart';
import 'package:human_face_generator/src/repository/authentication_repository/authentication_repository.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:universal_html/html.dart' as html;

class DrawingScreen extends StatefulWidget {
  const DrawingScreen({super.key});

  @override
  State<DrawingScreen> createState() => _Screen2State();
}

class _Screen2State extends State<DrawingScreen> {
  var selectedColor = Colors.black;
  var selectedWidth = 1.0;

  var historyDrawingPoints = <DrawingPoint>[];
  var drawingPoints = <DrawingPoint>[];
  DrawingPoint? currentDrawingPoint;
  Widget? imageOutput = Container();
  Uint8List? convertedBytes;
  final GlobalKey imageKey = GlobalKey();
  File? file;
  PlatformFile? _imageFile;
  bool show = true;

  var listBytes;
  void saveToImage(List<DrawingPoint?> points) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromPoints(const Offset(0.0, 0.0), const Offset(256, 256)),
    );
    Paint paint = Paint()
      ..color = const ui.Color.fromARGB(255, 255, 255, 255)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.0;
    final paint2 = Paint()
      ..style = PaintingStyle.fill
      ..color = const ui.Color.fromARGB(255, 0, 0, 0);
    canvas.drawRect(const Rect.fromLTWH(0, 0, 256, 256), paint2);
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        for (int j = 0; j < points[i]!.offsets.length - 1; j++) {
          canvas.drawLine(
            points[i]!.offsets[j],
            points[i]!.offsets[j + 1],
            paint,
          );
        }
      }
    }
    final picture = recorder.endRecording();
    final img = await picture.toImage(256, 256);
    final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);
    listBytes = Uint8List.view(pngBytes!.buffer);
    //File file = await writeBytes(listBytes);
    String base64 = base64Encode(listBytes);
    fetchResponse(base64);
  }

  void fetchResponse(var base64Image) async {
    var data = {"Image": base64Image};
    var url = Uri.parse(Constants.serverUrl);

    Map<String, String> headers = {
      'Content-type': 'application/json',
      'Accept': 'application/json',
      'Connection': "Keep-Alive",
    };
    var body = json.encode(data);
    try {
      var response = await http.post(url, body: body, headers: headers);

      final Map<String, dynamic> responseData = json.decode(response.body);
      String outputBytes = responseData['Image'];

      displayResponseImage(outputBytes.substring(2, outputBytes.length - 1));
    } catch (e) {
      // ignore: avoid_print
      // Display a Snackbar when an error occurs
      Get.showSnackbar(const GetSnackBar(
        message: "Server is down try again.",
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ));

      print(" *Error has Occured: $e");
      return null;
    }
  }

  void displayResponseImage(String bytes) async {
    Uint8List convertedBytes = base64Decode(bytes);
    if (convertedBytes.isNotEmpty) {
      show = false;
    }
    setState(() {
      imageOutput = RepaintBoundary(
        key: imageKey,
        child: SizedBox(
          width: 256,
          height: 256,
          child: Image.memory(convertedBytes, fit: BoxFit.contain),
        ),
      );
    });
  }

  void saveRealImageToGallery() async {
    if (imageOutput != null && show == false) {
      RenderRepaintBoundary boundary =
          imageKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Save the image to the device's gallery
      final result =
          await ImageGallerySaver.saveImage(Uint8List.fromList(pngBytes));
      // Check if the image was saved successfully
      if (result != null) {
        DialogHelper.showImageSavedDialog(context);
      } else {
        DialogHelper.showImageNotSavedDialog(context);
      }
    } else {
      DialogHelper.showImageNotSavedDialog(context);
    }
  }

  Future<ui.Image?> decodeImageFromFile(File imageFile) async {
    final Uint8List bytes = await imageFile.readAsBytes();
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(bytes, (ui.Image img) {
      completer.complete(img);
    });
    return completer.future;
  }

  Future<ui.Image?> decodeImageFromPlatformFile(
      PlatformFile platformFile) async {
    final Uint8List bytes = platformFile.bytes!;
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(bytes, (ui.Image img) {
      completer.complete(img);
    });
    return completer.future;
  }

  // Future<void> loadImage(XFile? file) async {
  //   try {
  //     if (file != null) {
  //       final File pickedImage = File(file.path);
  //       final decodedImage = await decodeImageFromFile(pickedImage);
  //       if (decodedImage != null &&
  //           decodedImage.width == 256 &&
  //           decodedImage.height == 256) {
  //         setState(() {
  //           //UserPickedImage = pickedImage;
  //         });
  //         var base64String = await fileToBase64(file);
  //         fetchResponse(base64String);
  //       } else {
  //         showImageNotSupportedDialog();
  //       }
  //     }
  //   } catch (e) {
  //     print('Error loading image: $e');
  //   }
  // }

  Future<String> fileToBase64(File file) async {
    try {
      List<int> bytes = await file.readAsBytes();
      return base64Encode(bytes);
    } catch (e) {
      print('Error converting file to base64: $e');
      return '';
    }
  }

  Future<String> platformFileToBase64(PlatformFile platformFile) async {
    try {
      // Read the bytes from the PlatformFile
      Uint8List bytes = platformFile.bytes!;
      // Encode the bytes to base64
      return base64Encode(bytes);
    } catch (e) {
      print('Error converting file to base64: $e');
      return '';
    }
  }

  // Future<void> _pickImage() async {
  //   final ImagePicker _picker = ImagePicker();
  //   XFile? image = await _picker.pickImage(source: ImageSource.gallery);

  //   if (image != null) {
  //     if (kIsWeb) {
  //       var f = await image.readAsBytes();
  //       setState(() {
  //         webImage = f;
  //         //UserPickedImage = File(); // Set to null as it's not being used
  //       });
  //     } else {
  //       var selected = File(image.path);
  //       setState(() {
  //         UserPickedImage = selected;
  //       });
  //     }
  //   } else {
  //     print('No image has been picked');
  //   }
  // }

  File? selectRandomImage() {
    const int totalImages = 10;
    Random random = Random();
    int randomIndex = random.nextInt(totalImages) + 1;
    String imagePath = 'assets/Sketches/$randomIndex.jpg';
    // Check if the image file exists
    File imageFile = File(imagePath);
    if (imageFile.existsSync()) {
      return imageFile;
    } else {
      // Handle the case when the image file doesn't exist
      print('Image file not found: $imagePath');
      return null;
    }
  }

  // Method to pick and display an image file
  Future<void> _pickImage(context) async {
    try {
      // Pick an image file using file_picker package
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      // If user cancels the picker, do nothing
      if (result == null) return;
      if (!kIsWeb) {
        file = File(result.files.single.path!);
        final decodedImage = await decodeImageFromFile(file!);
        if (decodedImage!.width != 256 && decodedImage.height != 256) {
          DialogHelper.showImageNotSupportedDialog(context);
          return;
        }
        var base64String = await fileToBase64(file!);
        fetchResponse(base64String);
      }
      if (kIsWeb) {
        _imageFile = result.files.first;
        final decodedImage = await decodeImageFromPlatformFile(_imageFile!);
        if (decodedImage!.width != 256 && decodedImage.height != 256) {
          DialogHelper.showImageNotSupportedDialog(context);
          _imageFile = null;
          return;
        }
        // If user picks an image, update the state with the new image file
        var base64String = await platformFileToBase64(_imageFile!);
        fetchResponse(base64String);
      }
    } catch (e) {
      // If there is an error, show a snackbar with the error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }
  }

// Method for web platforms
  void saveImageToGalleryWeb() async {
    try {
      if (imageOutput != null && show == false) {
        RenderRepaintBoundary boundary = imageKey.currentContext!
            .findRenderObject() as RenderRepaintBoundary;
        ui.Image image = await boundary.toImage(pixelRatio: 3.0);
        ByteData? byteData =
            await image.toByteData(format: ui.ImageByteFormat.png);
        Uint8List pngBytes = byteData!.buffer.asUint8List();

        // Convert the image bytes to base64
        String base64Image = base64Encode(pngBytes);

        // Create an anchor element
        final anchor = html.AnchorElement(
            href: 'data:application/octet-stream;base64,$base64Image')
          ..setAttribute('download', 'image.png')
          ..style.display = 'none';

        // Add the anchor element to the document body
        html.document.body!.children.add(anchor);

        // Trigger a click event on the anchor element
        anchor.click();

        // Remove the anchor element from the document body
        html.document.body!.children.remove(anchor);

        // Show a success message
        DialogHelper.showImageSavedDialogWb(context);
      } else {
        DialogHelper.showImageNotSavedDialog(context);
      }
    } catch (e) {
      // Handle any exceptions
      print('Error saving image: $e');
      DialogHelper.showImageNotSavedDialog;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => Get.to(
            () => const ProfileScreen(),
          ),
        ),
        title: Text(
          "Face Sketch To Real",
          style: GoogleFonts.poppins(
            fontSize: 16.0,
            fontWeight: FontWeight.w600,
            color: tWhiteColor,
          ),
        ),
        backgroundColor: tPrimaryColor,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                        width: 257,
                        height: 257,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(0),
                          ),
                          color: Colors.white,
                          border: Border.all(
                            color: const Color.fromARGB(
                                255, 0, 0, 0), // Set the border color here
                            width: 1, // Set the border width here
                          ),
                        ),
                        child: _imageFile == null
                            ? GestureDetector(
                                onPanStart: (details) {
                                  setState(() {
                                    currentDrawingPoint = DrawingPoint(
                                      id: DateTime.now().microsecondsSinceEpoch,
                                      offsets: [
                                        details.localPosition,
                                      ],
                                      color: selectedColor,
                                      width: selectedWidth,
                                    );
                                    if (currentDrawingPoint == null) return;
                                    drawingPoints.add(currentDrawingPoint!);
                                    historyDrawingPoints =
                                        List.of(drawingPoints);
                                  });
                                },
                                onPanUpdate: (details) {
                                  setState(() {
                                    if (currentDrawingPoint == null) return;
                                    currentDrawingPoint =
                                        currentDrawingPoint?.copyWith(
                                      offsets: currentDrawingPoint!.offsets
                                        ..add(details.localPosition),
                                    );
                                    drawingPoints.last = currentDrawingPoint!;
                                    historyDrawingPoints =
                                        List.of(drawingPoints);
                                  });
                                },
                                onPanEnd: (details) {
                                  saveToImage(drawingPoints);
                                  currentDrawingPoint = null;
                                },
                                child: CustomPaint(
                                  painter: DrawingPainter(
                                    drawingPoints: drawingPoints,
                                  ),
                                  size: const Size(256, 256),
                                ),
                              )
                            : kIsWeb
                                ? Image.memory(
                                    Uint8List.fromList(_imageFile!.bytes!),
                                    fit: BoxFit.fill,
                                  )
                                : Image.file(file!)),
                    const SizedBox(height: 50),
                    if (show)
                      Container(
                        width: 257,
                        height: 257,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 1.0),
                        ),
                        child: const Center(
                            child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "No AI generated image yet\nDraw a face sketch first\nIn the above box!",
                              textAlign: TextAlign.center,
                            ),
                          ],
                        )),
                      ),
                    if (show == false)
                      Container(
                        width: 257,
                        height: 257,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 1.0),
                        ),
                        child: imageOutput ??
                            const Center(
                                child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "No AI generated image yet\nDraw a face sketch first\nIn the above box!",
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            )),
                      ),
                  ],
                ),
                const SizedBox(width: 20),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 256,
                      width: 40,
                      decoration: const BoxDecoration(
                        color: tPrimaryColor,
                        borderRadius: BorderRadius.all(
                          Radius.circular(0),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: () {
                              if (drawingPoints.isNotEmpty &&
                                  historyDrawingPoints.isNotEmpty) {
                                setState(() {
                                  drawingPoints.removeLast();
                                  saveToImage(drawingPoints);
                                });
                              }
                            },
                            icon: const Icon(
                              Icons.undo,
                              color: Color.fromARGB(255, 255, 255, 255),
                            ),
                          ),
                          const SizedBox(
                            height: 0,
                          ),
                          IconButton(
                            onPressed: () {
                              if (drawingPoints.length <
                                  historyDrawingPoints.length) {
                                // 6 length 7
                                final index = drawingPoints.length;
                                drawingPoints.add(historyDrawingPoints[index]);
                                saveToImage(drawingPoints);
                              }
                            },
                            icon: const Icon(
                              Icons.redo,
                              color: Color.fromARGB(255, 255, 255, 255),
                            ),
                          ),
                          const SizedBox(
                            height: 0,
                          ),
                          IconButton(
                            onPressed: () {
                              drawingPoints.clear();
                              historyDrawingPoints.clear();
                              setState(() {
                                file = null;
                                _imageFile = null;
                              });
                            },
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(
                            height: 0,
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                if (drawingPoints.isNotEmpty) {
                                  final result = ImageGallerySaver.saveImage(
                                      Uint8List.fromList(listBytes));
                                  if (result != null) {
                                    DialogHelper.showImageSavedDialog(context);
                                  } else {
                                    DialogHelper.showImageNotSavedDialog(
                                        context);
                                  }
                                } else {
                                  DialogHelper.showImageNotSavedDialog(context);
                                }
                              });
                            },
                            icon: const Icon(
                              Icons.download,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(
                            height: 0,
                          ),
                          IconButton(
                            onPressed: () {
                              _pickImage(context);
                            },
                            icon: const Icon(
                              Icons.upload,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 50),
                    Container(
                      height: 256,
                      width: 40,
                      decoration: const BoxDecoration(
                        color: tPrimaryColor,
                        borderRadius: BorderRadius.all(
                          Radius.circular(0),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: () {
                              setState(() {
                                imageOutput = null;
                              });
                            },
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(
                            height: 0,
                          ),
                          IconButton(
                            onPressed: () {
                              if (kIsWeb) {
                                saveImageToGalleryWeb();
                              }
                              if (!kIsWeb) {
                                saveRealImageToGallery();
                              }
                            },
                            icon: const Icon(
                              Icons.download,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
