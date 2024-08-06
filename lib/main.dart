import 'dart:io';
import 'dart:math';
import 'package:another_flushbar/flushbar.dart';
import 'package:another_flushbar/flushbar_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:permission_handler/permission_handler.dart';

main() {
  runApp(
    Phoenix(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: MyApp(),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final picker = ImagePicker();
  final pdf = pw.Document();
  final List<File> _image = [];
  final permission = Permission.storage;
  String? myFolder;
  late final double? opticalSize;


  @override
  Widget build(BuildContext context) {
    getStoragePermission();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Convert Image to PDF"),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            color: Colors.white,
            onPressed: () => Phoenix.rebirth(context),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            color: Colors.white,
            onPressed: () async {
              if (_image.isNotEmpty) {
                createPDF();
                savePDF();
              } else {
                showPrintedMessage('Error', 'No Image Selected');
              }
            },
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: getImageFromGallery,
            backgroundColor: Colors.deepPurple,
            child: const Icon(Icons.photo_library, opticalSize: 68, color: Colors.white70),
          ),
          const SizedBox(width: 10),
          FloatingActionButton(
            onPressed: getImageFromCamera,
            backgroundColor: Colors.deepPurple,
            child: const Icon(Icons.camera, opticalSize: 68, color: Colors.white70),
          ),
        ],
      ),
      body: _image.isNotEmpty
          ? ListView.builder(
        itemCount: _image.length,
        itemBuilder: (context, index) => Container(
          height: 450,
          width: double.infinity,
          margin: const EdgeInsets.all(10),
          child: Image.file(
            _image[index],
            fit: BoxFit.cover,
          ),
        ),
      )
          : Container(),
    );
  }

  getImageFromGallery() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      if (pickedFile != null) {
        _image.add(File(pickedFile.path));
      } else {
        if (kDebugMode) {
          print('No image selected');
        }
      }
    });
  }

  getImageFromCamera() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    setState(() {
      if (pickedFile != null) {
        _image.add(File(pickedFile.path));
      } else {
        if (kDebugMode) {
          print('No image selected');
        }
      }
    });
  }

  createPDF() async {
    for (var img in _image) {
      final image = pw.MemoryImage(img.readAsBytesSync());

      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context contex) {
          return pw.Center(child: pw.Image(image));
        },
      ));
    }
  }
  createFolder(String myfoolder,String myfoolder2) async {
    PermissionStatus status = await Permission.storage.request();
    //PermissionStatus status1 = await Permission.accessMediaLocation.request();
    PermissionStatus status2 = await Permission.manageExternalStorage.request();
    print('status $status   -> $status2');
    if (status.isGranted && status2.isGranted) {
      const path = '/storage/emulated/0/DCIM/';
      bool checkFolder = _checkDirectoryExistsSync('$path/$myfoolder');
      print(checkFolder);
      if (!checkFolder) {
        Directory('$path/$myfoolder/').create(recursive: true).then((Directory directory) {});

      } else {
        if (kDebugMode) {
          print ('Exista deja: $myfoolder');
        }
      }
      bool checkFolder2 = _checkDirectoryExistsSync('$path/$myfoolder/$myfoolder2');

      if (!checkFolder2) {
        Directory('$path/$myfoolder/$myfoolder2').create(
            recursive: true).then((Directory directory) {}); }
      else {
        if (kDebugMode) {
          print ('Exista deja: $myfoolder2');
        }
      }



      // The created directory is returned as a Future.

    }

  }
  bool _checkDirectoryExistsSync(String path) {

    return Directory(path).existsSync();

  }

  savePDF() async {
    String myappfolder = 'ImagetoPDF';

//prepare some infos
    DateTime now = DateTime.now();
    String filenameMili = DateTime.now().millisecondsSinceEpoch.toString();
    Random random = Random();
    int randomNumber = random.nextInt(19100)+11; // from 11 upto 19100 included
    String foldername2save = DateFormat('dMMMyyyy').format(now);
    String filename2save = ('$filenameMili-$randomNumber');
    //get storage access
    createFolder('$myappfolder','$foldername2save');
    await Future.delayed(Duration(seconds: 4));

    try {


      // final dir = await getExternalStorageDirectory();
      final rootdir = '/storage/emulated/0/DCIM/$myappfolder/$foldername2save';
      if (kDebugMode) {
        print(rootdir);
      }
      //final file = File('${dir?.path}/$filename2save.pdf');

      if (1 == 1 ) {

        // var directory = await Directory('$rootdir/$foldername2save').create(recursive: true);
        //  print(directory);

        final file = File('$rootdir/$filename2save.pdf');



        if (kDebugMode) {
          print(file);
        }

        await file.writeAsBytes(await pdf.save());
        showPrintedMessage('Success', 'Saved as $filename2save to Documents');
      }
    } catch (e) { if (kDebugMode) {
      print(e);
    }

    showPrintedMessage('error', e.toString());
    }
  }
  Future getStoragePermission() async {
    PermissionStatus status = await Permission.storage.request();
    //PermissionStatus status1 = await Permission.accessMediaLocation.request();
    PermissionStatus status2 = await Permission.manageExternalStorage.request();
    if (kDebugMode) {
      print('status $status   -> $status2');
    }
    if (status.isGranted && status2.isGranted) {
      return true;
    } else if (status.isPermanentlyDenied || status2.isPermanentlyDenied) {
      await openAppSettings();
    } else if (status.isDenied) {
      if (kDebugMode) {
        print('Permission Denied');
      }
    }
  }
  showPrintedMessage(String title, String msg) {
    Flushbar(
      title: title,
      message: msg,
      duration: const Duration(seconds: 5),
      icon: const Icon(
        Icons.info,
        color: Colors.purpleAccent,
      ),
    ).show(context);
  }
}
