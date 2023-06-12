import 'dart:io';
import 'package:caption_tool/color_schemes.g.dart';
import 'package:caption_tool/model/caption.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lyricool"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            EntryButton(
              width: 320.0,
              height: 96.0,
              color: lightColorScheme.primaryContainer,
              onTap: () {
                ///todo: copy from close_caption_converter.
                Navigator.pushNamed(context, "SearchPage");
              },
              child: Text(
                "导入Bilibili CC字幕",
                style: TextStyle(
                  color: lightColorScheme.onPrimaryContainer,
                  fontSize: 24.0,
                ),
              ),
            ),
            const SizedBox(
              height: 16.0,
            ),
            EntryButton(
              width: 320.0,
              height: 96.0,
              color: lightColorScheme.primaryContainer,
              onTap: () {
                Navigator.pushNamed(context, "FullScreenTextField");
              },
              child: Text(
                "导入格式化文本",
                style: TextStyle(
                  color: lightColorScheme.onPrimaryContainer,
                  fontSize: 24.0,
                ),
              ),
            ),
            const SizedBox(
              height: 16.0,
            ),
            EntryButton(
              width: 320.0,
              height: 96.0,
              color: lightColorScheme.primaryContainer,
              onTap: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("请选择.lrc文件"),
                  ),
                );
                FilePickerResult? result =
                    await FilePicker.platform.pickFiles();

                if (result == null) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("未选择文件"),
                      ),
                    );
                  }
                } else if (result.files.single.extension == "lrc") {
                  var captionFile = File(result.files.single.path!);

                  var lrcCaption = await LrcCaption.fromLrcFile(lrc: captionFile);

                  if (context.mounted) {
                    Navigator.pushNamed(
                      context,
                      "CaptionEditingPage",
                      arguments: lrcCaption,
                    );
                  }
                } else if (result.files.single.extension != "lrc") {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("不支持的文件类型；请选择.lrc文件"),
                      ),
                    );
                  }
                }
              },
              child: Text(
                "打开文件",
                style: TextStyle(
                  color: lightColorScheme.onPrimaryContainer,
                  fontSize: 24.0,
                ),
              ),
            ),
            const SizedBox(
              height: 16.0,
            ),
            EntryButton(
              width: 320.0,
              height: 96.0,
              color: lightColorScheme.primaryContainer,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return const CreateCaptionDialog();
                  },
                );
              },
              child: Text(
                "新建歌词文件",
                style: TextStyle(
                  color: lightColorScheme.onPrimaryContainer,
                  fontSize: 24.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CreateCaptionDialog extends StatelessWidget {
  const CreateCaptionDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final titleEditingController = TextEditingController();
    return SimpleDialog(
      contentPadding: const EdgeInsets.fromLTRB(24.0, 12.0, 24.0, 16.0),
      title: const Text(
        "新建歌词文件",
      ),
      children: [
        TextField(
          controller: titleEditingController,
          decoration: const InputDecoration(
            labelText: "歌词文件名",
          ),
        ),
        const SizedBox(
          height: 12.0,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("取消"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);

                Navigator.pushNamed(
                  context,
                  "CaptionEditingPage",
                  arguments: LrcCaption(
                    lines: [],
                    projectName: titleEditingController.text.trim().isEmpty
                        ? "未命名"
                        : titleEditingController.text,
                  ),
                );
              },
              child: const Text("确认"),
            ),
          ],
        )
      ],
    );
  }
}

class EntryButton extends StatelessWidget {
  const EntryButton({
    super.key,
    required this.width,
    required this.height,
    required this.child,
    this.onTap,
    required this.color,
  });

  final double width;
  final double height;
  final Widget child;
  final Function()? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Material(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        color: color,
        child: InkWell(
          borderRadius: BorderRadius.circular(12.0),
          onTap: onTap,
          child: Center(
            child: child,
          ),
        ),
      ),
    );
  }
}
