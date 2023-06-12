// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:io';

import 'package:caption_tool/model/caption.dart';
import 'package:caption_tool/page/preview_view.dart';
import 'package:caption_tool/page/set_caption_time_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'delete_view.dart';

class CaptionEditingPage extends StatefulWidget {
  const CaptionEditingPage({super.key, required this.caption});

  final LrcCaption caption;

  @override
  State<CaptionEditingPage> createState() => _CaptionEditingPageState();
}

class _CaptionEditingPageState extends State<CaptionEditingPage> {
  ///控制undo和redo
  var stepService = UndoRedo(
    undos: <LrcCaption>[],
    redos: <LrcCaption>[],
    length: 5,
  );

  @override
  Widget build(BuildContext context) {
    var addCaptionLineBtn = IconButton(
      tooltip: "添加歌词",
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

          stepService.addUndo(toAdd: widget.caption);

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
      tooltip: "删除歌词",
      onPressed: () async {
        List? deleteList;

        deleteList = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return DeleteCaptionView(
                deleteList: [
                  for (int i = 0; i < widget.caption.lines.length; i++) false
                ],
                caption: widget.caption,
              );
            },
          ),
        );

        if (deleteList != null) {
          stepService.addUndo(toAdd: widget.caption);
          for (int i = widget.caption.lines.length - 1; i >= 0; i--) {
            if (deleteList[i] == true) {
              widget.caption.lines.removeAt(i);
              deleteList.removeAt(i);
            }
          }
        }

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
        stepService.addUndo(toAdd: widget.caption);
        await Navigator.push(context, MaterialPageRoute(
          builder: (context) {
            return SetCaptionTimeView(caption: widget.caption);
          },
        ));

        setState(() {});
      },
      icon: const Icon(Icons.timer),
    );

    var mergeBtn = IconButton(
      tooltip: "合并歌词",
      onPressed: () async {
        String? separator = await showDialog(
          context: context,
          builder: (context) {
            return const MergeLyricDialog();
          },
        );
        if (separator != null) {
          stepService.addUndo(toAdd: widget.caption);
          widget.caption.mergeSameTimeLines(separator: separator);
        }
        setState(() {});
      },
      icon: const Icon(Icons.merge),
    );

    var splitBtn = IconButton(
      tooltip: "拆分歌词",
      onPressed: () async {
        String? separator = await showDialog(
          context: context,
          builder: (context) {
            return const SplitLyricDialog();
          },
        );
        if (separator != null) {
          stepService.addUndo(toAdd: widget.caption);
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
              content: Text("保存到 $lyricFileDir"),
            ),
          );
        }
      },
      child: const Icon(Icons.save),
    );

    var sortBtn = IconButton(
      onPressed: () {
        stepService.addUndo(toAdd: widget.caption);
        widget.caption.stableSort();
        setState(() {});
      },
      icon: const Icon(Icons.sort),
      tooltip: "按时间戳排序",
    );
    var delayBtn = IconButton(
      onPressed: () async {
        Duration? delay = await showDialog(
          context: context,
          builder: (context) {
            return const SetDelayDialog();
          },
        );
        if (delay != null) {
          stepService.addUndo(toAdd: widget.caption);
          for (var element in widget.caption.lines) {
            if (element.time > -delay) {
              element.time += delay;
            } else {
              element.time = Duration.zero;
            }
          }
          setState(() {});
        }
      },
      icon: const Icon(Icons.more_time),
      tooltip: "调整时间轴",
    );
    var renameBtn = IconButton(
      tooltip: "重命名",
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
          stepService.addUndo(toAdd: widget.caption);
          widget.caption.projectName = newTitle;
        }

        setState(() {});
      },
      icon: const Icon(Icons.drive_file_rename_outline),
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
          renameBtn,
          const SizedBox(width: 8.0),
        ],
      ),
      body: ListView.builder(
        itemCount: widget.caption.lines.length,
        itemBuilder: captionLineBuilder,
      ),
      bottomNavigationBar: BottomAppBar(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        child: Row(
          children: [
            addCaptionLineBtn,
            const SizedBox(width: 4.0),
            deleteCaptionLineBtn,
            const SizedBox(width: 4.0),
            previewBtn,
            const SizedBox(width: 4.0),
            setCaptionTimeBtn,
            const SizedBox(width: 4.0),
            mergeBtn,
            const SizedBox(width: 4.0),
            splitBtn,
            const SizedBox(width: 4.0),
            sortBtn,
            const SizedBox(width: 4.0),
            delayBtn,
            const SizedBox(width: 4.0),
            IconButton(
              tooltip: "撤销",
              onPressed: stepService.canUndo()
                  ? () {
                      widget.caption.copyFrom(
                        from: stepService.undo(now: widget.caption),
                      );
                      setState(() {});
                    }
                  : null,
              icon: const Icon(Icons.undo),
            ),
            const SizedBox(width: 4.0),
            IconButton(
              tooltip: "重做",
              onPressed: stepService.canRedo()
                  ? () {
                      widget.caption.copyFrom(
                        from: stepService.redo(now: widget.caption),
                      );
                      setState(() {});
                    }
                  : null,
              icon: const Icon(Icons.redo),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endContained,
      floatingActionButton: saveFAB,
    );
  }

  Future<String> get getLrcFileDir async {
    if (Platform.isAndroid) {
      return "${(await getExternalStorageDirectory())!.path}${Platform.pathSeparator}lyrics${Platform.pathSeparator}${widget.caption.projectName}.lrc";
    }
    return "${(await getApplicationDocumentsDirectory()).path}${Platform.pathSeparator}lyrics${Platform.pathSeparator}${widget.caption.projectName}.lrc";
  }

  Widget captionLineBuilder(context, index) {
    return InkWell(
      onTap: () async {
        LrcCaptionLine? result = await showDialog(
          context: context,
          builder: (context) {
            return EditCaptionLineDialog(
              captionLine: widget.caption.lines[index],
            );
          },
        );
        if (result != null) {
          stepService.addUndo(toAdd: widget.caption);
          widget.caption.lines[index] = result;
        }

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
        const Text("合并所有时间戳相同的歌词"),
        const Text("示例："),
        Row(
          children: [
            const Expanded(
              child: Column(
                children: [
                  Text("[01:56.32]line1"),
                  Text("[01:56.32]line2"),
                ],
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
            Expanded(
              child: Center(
                child: ValueListenableBuilder(
                  valueListenable: separatorNotifier,
                  builder: (context, value, child) {
                    return Text("[01:56.32]line1${value}line2");
                  },
                ),
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
            Expanded(
              child: Center(
                child: ValueListenableBuilder(
                  valueListenable: separatorNotifier,
                  builder: (context, value, child) {
                    return Text("[01:56.32]line1${value}line2");
                  },
                ),
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
            const Expanded(
              child: Column(
                children: [
                  Text("[01:56.32]line1"),
                  Text("[01:56.32]line2"),
                ],
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

class SetDelayDialog extends StatelessWidget {
  const SetDelayDialog({super.key});

  @override
  Widget build(BuildContext context) {
    var minEditingController = TextEditingController(text: "00");
    var secEditingController = TextEditingController(text: "00");
    var msEditingController = TextEditingController(text: "000");

    var minTextField = TextField(
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp("[0-9-]"))],
      maxLength: 3,
      controller: minEditingController,
      decoration: const InputDecoration(labelText: "min", suffixText: "min"),
    );
    var secTextField = TextField(
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp("[0-9-]"))],
      maxLength: 3,
      controller: secEditingController,
      decoration: const InputDecoration(labelText: "s", suffixText: "s"),
    );
    var msTextField = TextField(
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp("[0-9-]"))],
      maxLength: 4,
      controller: msEditingController,
      decoration: const InputDecoration(labelText: "ms", suffixText: "ms"),
    );

    return SimpleDialog(
      title: const Text("调整时间轴"),
      contentPadding: const EdgeInsets.fromLTRB(24.0, 12.0, 24.0, 16.0),
      children: [
        const Text("将所有歌词的时间轴提前或延后一段指定的时间"),
        Row(
          children: [
            Expanded(child: minTextField),
            const SizedBox(width: 8.0),
            Expanded(child: secTextField),
            const SizedBox(width: 8.0),
            Expanded(child: msTextField),
          ],
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
                var min = int.tryParse(minEditingController.text);
                var sec = int.tryParse(secEditingController.text);
                var ms = int.tryParse(msEditingController.text);
                Duration? delay;
                if (min != null && sec != null && ms != null) {
                  var inMilliseconds = min * 60 * 1000 + sec * 1000 + ms;
                  delay = Duration(milliseconds: inMilliseconds);
                }

                Navigator.pop(
                  context,
                  delay,
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
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      maxLength: 2,
      controller: minEditingController,
      decoration: const InputDecoration(labelText: "min", suffixText: "min"),
    );
    var secTextField = TextField(
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      maxLength: 2,
      controller: secEditingController,
      decoration: const InputDecoration(labelText: "s", suffixText: "s"),
    );
    var msTextField = TextField(
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      maxLength: 3,
      controller: msEditingController,
      decoration: const InputDecoration(labelText: "ms", suffixText: "ms"),
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

        var result = LrcCaptionLine(
            content: contentEditingController.text, time: duration);

        Navigator.pop(context, result);
      },
      child: const Text("确认"),
    );

    return SimpleDialog(
      contentPadding: const EdgeInsets.fromLTRB(24.0, 12.0, 24.0, 16.0),
      title: const Text("修改歌词"),
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
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      maxLength: 2,
      controller: minEditingController,
      decoration: const InputDecoration(labelText: "min", suffixText: "min"),
    );
    var secTextField = TextField(
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      maxLength: 2,
      controller: secEditingController,
      decoration: const InputDecoration(labelText: "s", suffixText: "s"),
    );
    var msTextField = TextField(
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      maxLength: 3,
      controller: msEditingController,
      decoration: const InputDecoration(labelText: "ms", suffixText: "ms"),
    );
    var contentTextField = TextField(
      controller: contentEditingController,
      decoration: const InputDecoration(
        labelText: "内容",
      ),
    );
    var posTextField = TextField(
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
        "新建歌词",
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
