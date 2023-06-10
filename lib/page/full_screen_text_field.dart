import 'package:caption_tool/model/caption.dart';
import 'package:flutter/material.dart';

class FullScreenTextField extends StatefulWidget {
  const FullScreenTextField({super.key});

  @override
  State<FullScreenTextField> createState() => _FullScreenTextFieldState();
}

class _FullScreenTextFieldState extends State<FullScreenTextField> {
  var titleEditingController = TextEditingController();
  var contentEditingController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text("导入格式化文本"),
      ),
      body: Padding(
        padding: const EdgeInsets.only(
          left: 16.0,
          right: 16.0,
        ),
        child: Column(
          children: [
            TextField(
              controller: titleEditingController,
              maxLines: 1,
              decoration: const InputDecoration(
                labelText: "字幕名",
              ),
            ),
            const SizedBox(
              height: 16.0,
            ),
            SingleChildScrollView(
              child: SizedBox(
                height: MediaQuery.of(context).size.height - 176,
                child: TextField(
                  controller: contentEditingController,
                  maxLines: null,
                  expands: true,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: "将文本粘贴到这里\n确保一行只有一句字幕\n点击右下角按钮进行转换",
                    hintStyle: TextStyle(fontSize: 18.0),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(
            context,
            "CaptionEditingPage",
            arguments: LrcCaption.fromFormattedText(
              title: titleEditingController.text,
              formattedText: contentEditingController.text,
            ),
          );
        },
        child: const Icon(Icons.drive_file_move),
      ),
    );
  }
}
