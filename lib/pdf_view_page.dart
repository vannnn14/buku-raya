import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

PDFViewerPage({required String pdfUrl}) {
  // Ubah URL Google Drive ke format Google Drive Viewer
  final String fileId = pdfUrl.split('id=')[1];
  final String viewerUrl = 'https://drive.google.com/viewerng/viewer?embedded=true&url=https://drive.google.com/uc?id=$fileId';
  
  return Scaffold(
    appBar: AppBar(leading: BackButton()),
    body: InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(viewerUrl)),
      // ... rest of your code
    ),
  );
}