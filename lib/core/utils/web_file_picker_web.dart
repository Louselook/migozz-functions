import 'dart:html' as html;

Future<String?> pickDocumentWeb() async {
  final uploadInput = html.FileUploadInputElement();
  uploadInput.accept = '.pdf,.doc,.docx,.txt,.xls,.xlsx';
  uploadInput.click();

  await uploadInput.onChange.first;
  if (uploadInput.files != null && uploadInput.files!.isNotEmpty) {
    final file = uploadInput.files!.first;
    return file.name;
  }
  return null;
}
