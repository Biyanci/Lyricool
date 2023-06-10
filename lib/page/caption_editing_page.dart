// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:io';

import 'package:caption_tool/model/caption.dart';
import 'package:caption_tool/page/preview_view.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'delete_view.dart';

class CaptionEditingPage extends StatefulWidget {
  const CaptionEditingPage({super.key, required this.caption});

  final LrcCaption caption;

  @override
  State<CaptionEditingPage> createState() => _CaptionEditingPageState();
}

class _CaptionEditingPageState extends State<CaptionEditingPage> {
  @override
  Widget build(BuildContext context) {
    List<bool> deleteList = [
      for (int i = 0; i < widget.caption.lines.length; i++) false
    ];
    var addCaptionLineBtn = IconButton(
      tooltip: "添加字幕",
      onPressed: () async {
        ///result[0]: CaptionLine; result[1]: position
        var result = await showDialog(
          context: context,
          builder: (context) {
            return const AddCaptionLineDialog();
          },
        ) as List?;

        if (result != null) {
          var captionLine = result[0] as LrcCaptionLine;
          var pos = result[1];

          if (pos == null || pos > widget.caption.lines.length) {
            widget.caption.lines.add(captionLine);
          } else {
            widget.caption.lines.insert(pos, captionLine);
          }
        }

        setState(() {});
      },
      icon: const Icon(Icons.add),
    );
    var deleteCaptionLineBtn = IconButton(
      tooltip: "删除字幕",
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return DeleteCaptionView(
                  deleteList: deleteList, caption: widget.caption);
            },
          ),
        );
        setState(() {});
      },
      icon: const Icon(Icons.delete),
    );
    var previewBtn = IconButton(
      tooltip: "预览",
      onPressed: () async {
        var _caption = LrcCaption.from(widget.caption);
        _caption.mergeSameTimeLines(separator: "\n");
        var globalKeys = [
          for (int i = 0; i < _caption.lines.length; i++) GlobalKey()
        ];
        await Navigator.push(context, MaterialPageRoute(
          builder: (context) {
            return PreviewView(
              source: _caption,
              globalKeys: globalKeys,
            );
          },
        ));
      },
      icon: const Icon(Icons.preview),
    );
    var setCaptionTimeBtn = IconButton(
      tooltip: "打轴",
      onPressed: () async {
        await Navigator.pushNamed(
          context,
          "SetCaptionTimeView",
          arguments: widget.caption,
        );
        setState(() {});
      },
      icon: const Icon(Icons.timer),
    );

    var mergeBtn = IconButton(
      tooltip: "合并歌词",
      onPressed: () async {
        var separator = await showDialog<String>(
          context: context,
          builder: (context) {
            return const MergeLyricDialog();
          },
        );
        if (separator != null) {
          widget.caption.mergeSameTimeLines(separator: separator);
        }
        setState(() {});
      },
      icon: const Icon(Icons.merge),
    );

    var splitBtn = IconButton(
      tooltip: "拆分歌词",
      onPressed: () async {
        var separator = await showDialog<String>(
          context: context,
          builder: (context) {
            return const SplitLyricDialog();
          },
        );
        if (separator != null) {
          widget.caption.split(separator: separator);
        }
        setState(() {});
      },
      icon: const Icon(Icons.horizontal_split),
    );

    var saveFAB = FloatingActionButton(
      tooltip: "保存",
      onPressed: () async {
        String lyricFileDir = await getLrcFileDir;
        String rawLyricText = "";
        for (var element in widget.caption.lines) {
          rawLyricText += "[${element.toFormattedTime()}]${element.content}\n";
        }
        var lyricFile = await File(lyricFileDir).create(recursive: true);
        await lyricFile.writeAsString(rawLyricText);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("save to $lyricFileDir"),
            ),
          );
        }
      },
      child: const Icon(Icons.save),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.caption.projectName),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              String? newTitle = await showDialog(
                context: context,
                builder: (context) {
                  var titleEditingController =
                      TextEditingController(text: widget.caption.projectName);
                  return RenameDialog(
                    titleEditingController: titleEditingController,
                  );
                },
              );
              if (newTitle != null) {
                widget.caption.projectName = newTitle;
              }

              setState(() {});
            },
            icon: const Icon(Icons.drive_file_rename_outline),
          ),
          const SizedBox(width: 8.0),
        ],
      ),
      body: ListView.builder(
        itemCount: widget.caption.lines.length,
        itemBuilder: captionLineBuilder,
      ),
      bottomNavigationBar: BottomAppBar(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 2.0),
        child: Row(
          children: [
            addCaptionLineBtn,
            deleteCaptionLineBtn,
            previewBtn,
            setCaptionTimeBtn,
            mergeBtn,
            splitBtn,
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endContained,
      floatingActionButton: saveFAB,
    );
  }

  Future<String> get getLrcFileDir async => "${(await getExternalStorageDirectory())!.path}${Platform.pathSeparator}lyrics${Platform.pathSeparator}${widget.caption.projectName}.lrc";

  Widget? captionLineBuilder(context, index) {
    return InkWell(
      onTap: () async {
        await showDialog(
          context: context,
          builder: (context) {
            return EditCaptionLineDialog(
              captionLine: widget.caption.lines[index],
            );
          },
        );
        setState(() {});
      },
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 24.0, right: 16.0),
        mouseCursor: SystemMouseCursors.click,
        leading: Text(index.toString()),
        title: Text(widget.caption.lines[index].content),
        trailing: Text(widget.caption.lines[index].toFormattedTime()),
      ),
    );
  }
}

class RenameDialog extends StatelessWidget {
  const RenameDialog({
    super.key,
    required this.titleEditingController,
  });

  final TextEditingController titleEditingController;

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text("重命名"),
      contentPadding: const EdgeInsets.fromLTRB(24.0, 12.0, 24.0, 16.0),
      children: [
        const SizedBox(height: 16.0),
        TextField(
          controller: titleEditingController,
          decoration: const InputDecoration(
            labelText: "标题",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16.0),
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
                Navigator.pop(context, titleEditingController.text);
              },
              child: const Text("确认"),
            ),
          ],
        )
      ],
    );
  }
}

class MergeLyricDialog extends StatelessWidget {
  const MergeLyricDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    var separatorEditingController = TextEditingController(text: " | ");
    var separatorNotifier = ValueNotifier(" | ");
    return SimpleDialog(
      title: const Text("合并歌词"),
      contentPadding: const EdgeInsets.fromLTRB(24.0, 12.0, 24.0, 16.0),
      children: [
        const Text("合并下一句时间戳相同的歌词"),
        const Text("示例："),
        Row(
          children: [
            const Column(
              children: [
                Text("[01:56.32]line1"),
                Text("[01:56.32]line2"),
              ],
            ),
            const SizedBox(
              width: 8.0,
            ),
            const Center(
              child: Text("->"),
            ),
            const SizedBox(
              width: 8.0,
            ),
            Center(
              child: ValueListenableBuilder(
                valueListenable: separatorNotifier,
                builder: (context, value, child) {
                  return Text("[01:56.32]line1${value}line2");
                },
              ),
            ),
          ],
        ),
        TextField(
          controller: separatorEditingController,
          decoration: const InputDecoration(
              labelText: "分隔符", helperText: "输入任意一个分隔符，在示例预览效果"),
          onChanged: (value) {
            separatorNotifier.value = value;
          },
        ),
        const SizedBox(
          height: 16.0,
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
                Navigator.pop<String>(
                  context,
                  separatorNotifier.value,
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

class SplitLyricDialog extends StatelessWidget {
  const SplitLyricDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    var separatorEditingController = TextEditingController();
    var separatorNotifier = ValueNotifier("");
    return SimpleDialog(
      title: const Text("拆分歌词"),
      contentPadding: const EdgeInsets.fromLTRB(24.0, 12.0, 24.0, 16.0),
      children: [
        const Text("以给定的分隔符拆分歌词"),
        const Text("示例："),
        Row(
          children: [
            Center(
              child: ValueListenableBuilder(
                valueListenable: separatorNotifier,
                builder: (context, value, child) {
                  return Text("[01:56.32]line1${value}line2");
                },
              ),
            ),
            const SizedBox(
              width: 8.0,
            ),
            const Center(
              child: Text("->"),
            ),
            const SizedBox(
              width: 8.0,
            ),
            const Column(
              children: [
                Text("[01:56.32]line1"),
                Text("[01:56.32]line2"),
              ],
            ),
          ],
        ),
        TextField(
          controller: separatorEditingController,
          decoration: const InputDecoration(
              labelText: "分隔符", helperText: "输入任意一个分隔符，在示例预览效果"),
          onChanged: (value) {
            separatorNotifier.value = value;
          },
        ),
        const SizedBox(
          height: 16.0,
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
                Navigator.pop<String>(
                  context,
                  separatorNotifier.value.trim().isEmpty
                      ? null
                      : separatorNotifier.value,
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

class EditCaptionLineDialog extends StatelessWidget {
  const EditCaptionLineDialog({
    super.key,
    required this.captionLine,
  });

  final LrcCaptionLine captionLine;

  @override
  Widget build(BuildContext context) {
    final inMilliseconds = captionLine.time.inMilliseconds;
    int min = (inMilliseconds / 1000 / 60).floor();
    int sec = (inMilliseconds % 60000 / 1000).floor();
    var ms = (inMilliseconds - (sec * 1000)) % 60000;
    final minEditingController = TextEditingController(text: min.toString());
    final secEditingController = TextEditingController(text: sec.toString());
    final msEditingController = TextEditingController(text: ms.toString());
    final contentEditingController =
        TextEditingController(text: captionLine.content);

    var minTextField = TextField(
      maxLength: 2,
      controller: minEditingController,
      decoration: const InputDecoration(
        labelText: "min",
      ),
    );
    var secTextField = TextField(
      maxLength: 2,
      controller: secEditingController,
      decoration: const InputDecoration(
        labelText: "s",
      ),
    );
    var msTextField = TextField(
      maxLength: 3,
      controller: msEditingController,
      decoration: const InputDecoration(
        labelText: "ms",
      ),
    );
    var contentTextField = TextField(
      controller: contentEditingController,
      decoration: const InputDecoration(
        labelText: "内容",
      ),
    );
    var cancelBtn = TextButton(
      onPressed: () {
        Navigator.pop(context);
      },
      child: const Text("取消"),
    );
    var confirmBtn = TextButton(
      onPressed: () {
        var _min = int.parse(minEditingController.text);
        var _sec = int.parse(secEditingController.text);
        var _ms = int.parse(msEditingController.text);
        var inMilliseconds = (_min * 60 + _sec) * 1000 + _ms;
        var duration = Duration(milliseconds: inMilliseconds);

        captionLine.content = contentEditingController.text;
        captionLine.time = duration;
        Navigator.pop(context);
      },
      child: const Text("确认"),
    );

    return SimpleDialog(
      contentPadding: const EdgeInsets.fromLTRB(24.0, 12.0, 24.0, 16.0),
      title: const Text("修改字幕"),
      children: [
        Row(
          children: [
            Expanded(child: minTextField),
            const SizedBox(width: 8.0),
            Expanded(child: secTextField),
            const SizedBox(width: 8.0),
            Expanded(child: msTextField),
          ],
        ),
        const SizedBox(height: 8.0),
        contentTextField,
        const SizedBox(height: 12.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [cancelBtn, confirmBtn],
        )
      ],
    );
  }
}

class AddCaptionLineDialog extends StatelessWidget {
  const AddCaptionLineDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final minEditingController = TextEditingController(text: "00");
    final secEditingController = TextEditingController(text: "00");
    final msEditingController = TextEditingController(text: "00");
    final contentEditingController = TextEditingController();
    final posEditingController = TextEditingController();

    var minTextField = TextField(
      maxLength: 2,
      controller: minEditingController,
      decoration: const InputDecoration(
        labelText: "min",
      ),
    );
    var secTextField = TextField(
      maxLength: 2,
      controller: secEditingController,
      decoration: const InputDecoration(
        labelText: "s",
      ),
    );
    var msTextField = TextField(
      maxLength: 3,
      controller: msEditingController,
      decoration: const InputDecoration(
        labelText: "ms",
      ),
    );
    var contentTextField = TextField(
      controller: contentEditingController,
      decoration: const InputDecoration(
        labelText: "内容",
      ),
    );
    var posTextField = TextField(
      controller: posEditingController,
      decoration: const InputDecoration(
        labelText: "添加到",
      ),
    );
    var cancelBtn = TextButton(
      onPressed: () {
        Navigator.pop(context);
      },
      child: const Text("取消"),
    );
    var confirmBtn = TextButton(
      onPressed: () {
        int? pos = int.tryParse(posEditingController.text);

        var min = int.parse(minEditingController.text);
        var sec = int.parse(secEditingController.text);
        var ms = int.parse(msEditingController.text);
        var inMilliseconds = (min * 60 + sec) * 1000 + ms;
        var duration = Duration(milliseconds: inMilliseconds);

        Navigator.pop(
          context,
          [
            LrcCaptionLine(
              content: contentEditingController.text,
              time: duration,
            ),
            pos,
          ],
        );
      },
      child: const Text("确认"),
    );

    return SimpleDialog(
      contentPadding: const EdgeInsets.fromLTRB(24.0, 12.0, 24.0, 16.0),
      title: const Text(
        "新建字幕",
      ),
      children: [
        Row(
          children: [
            Expanded(child: minTextField),
            const SizedBox(width: 8.0),
            Expanded(child: secTextField),
            const SizedBox(width: 8.0),
            Expanded(child: msTextField),
          ],
        ),
        contentTextField,
        const SizedBox(height: 8.0),
        posTextField,
        const SizedBox(height: 16.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [cancelBtn, confirmBtn],
        )
      ],
    );
  }
}
