// ignore_for_file: no_leading_underscores_for_local_identifiers
import 'dart:io';

import 'package:flutter/material.dart';

class UndoRedo {
  List<LrcCaption> undos;
  List<LrcCaption> redos;
  int length;

  UndoRedo({
    required this.undos,
    required this.redos,
    required this.length,
  });

  bool canUndo()=> undos.isNotEmpty;

  bool canRedo()=> redos.isNotEmpty;

  ///撤销，不能直接传值，要重新构造一次数据
  LrcCaption undo({required LrcCaption now}) {
    addRedo(toAdd: LrcCaption.from(now));
    return LrcCaption.from(undos.removeLast());
  }

  ///重做，不能直接传值，要重新构造一次数据
  LrcCaption redo({required LrcCaption now}) {
    addUndo(toAdd: LrcCaption.from(now));
    return LrcCaption.from(redos.removeLast());
  }

  ///记录上一步，不能直接传值，要重新构造一次数据
  void addUndo({required LrcCaption toAdd}) {
    if (undos.length < length) {
      undos.add(LrcCaption.from(toAdd));
    } else if (undos.length >= length) {
      undos.removeAt(0);
      undos.add(LrcCaption.from(toAdd));
    }
  }

  ///记录撤销的步骤，不能直接传值，要重新构造一次数据
  void addRedo({required LrcCaption toAdd}) {
    if (redos.length < length) {
      redos.add(LrcCaption.from(toAdd));
    } else if (redos.length >= length) {
      redos.removeAt(0);
      redos.add(LrcCaption.from(toAdd));
    }
  }
}

class BilibiliVideo {
  String title;
  String describe;
  Image cover;
  List<Map<String, dynamic>> captionList;

  BilibiliVideo(
      {required this.title,
      required this.describe,
      required this.captionList,
      required this.cover});
}

class LrcCaption {
  String projectName;
  List<LrcCaptionLine> lines;

  LrcCaption({required this.projectName, required this.lines});

  static LrcCaption from(LrcCaption from) {
    var lines = <LrcCaptionLine>[];
    for (var element in from.lines) {
      var newElement = LrcCaptionLine(
        content: element.content,
        time: Duration(milliseconds: element.time.inMilliseconds),
      );
      lines.add(newElement);
    }

    return LrcCaption(projectName: from.projectName, lines: lines);
  }

  static LrcCaption fromJsonMap({
    required String title,
    required List<dynamic> captionRawList,
  }) {
    List<LrcCaptionLine> lines = [];
    for (int i = 0; i < captionRawList.length; i++) {
      var secondsAll = double.parse(captionRawList[i]["from"].toString());
      var lyricTime = Duration(milliseconds: (secondsAll * 1000).toInt());

      var contents = captionRawList[i]["content"].toString().split("\n");

      if (contents.length == 1) {
        lines.add(LrcCaptionLine(content: contents[0], time: lyricTime));
      } else if (contents.length > 1) {
        for (int j = 0; j < contents.length; j++) {
          lines.add(LrcCaptionLine(content: contents[j], time: lyricTime));
        }
      }
    }

    return LrcCaption(projectName: title, lines: lines);
  }

  static LrcCaption fromFormattedText(
      {required String title, required String formattedText}) {
    var captionLines = formattedText.split("\n");
    for (int i = captionLines.length - 1; i >= 0; i--) {
      if (captionLines[i].trim().isEmpty) {
        captionLines.removeAt(i);
      }
    }

    return LrcCaption(
      lines: [
        for (int i = 0; i < captionLines.length; i++)
          LrcCaptionLine(content: captionLines[i], time: Duration.zero)
      ],
      projectName: title.trim().isEmpty ? "未命名" : title,
    );
  }

  static Future<LrcCaption> fromLrcFile({required File lrc}) async {
    var lrcRawText = await lrc.readAsString();
    var lrcLines = lrcRawText.split("\n");

    String name = "";
    if (Platform.isWindows) {
      name = lrc.path.substring(
        lrc.path.lastIndexOf("\\") + 1,
        lrc.path.lastIndexOf("."),
      );
    } else if (Platform.isAndroid) {
      name = lrc.path.substring(
        lrc.path.lastIndexOf("/") + 1,
        lrc.path.lastIndexOf("."),
      );
    } else {
      name = lrc.path;
    }

    var lines = <LrcCaptionLine>[];
    for (int i = 0; i < lrcLines.length; i++) {
      var fromLrc = LrcCaptionLine.fromLrcLine(lrcLine: lrcLines[i]);
      if (fromLrc == null) {
        continue;
      } else {
        lines.add(fromLrc);
      }
    }

    var lrcCaption = LrcCaption(
      lines: lines,
      projectName: name,
    );

    ///sort by second
    lrcCaption.stableSort();

    return lrcCaption;
  }

  void copyFrom({required LrcCaption from}){
    projectName=from.projectName;
    lines=from.lines;
  }

  ///合并相同时间戳的歌词
  ///before:
  ///[01:56.32]line1
  ///[01:56.32]line2
  ///after:
  ///[01:56.32]line1 [separator] line2
  void mergeSameTimeLines({String separator = " | "}) {
    stableSort();

    List<int> sameTimeLyricIndexes = [];

    int next = 1;

    for (int i = 0; i < lines.length - 1;) {
      if (i + next < lines.length) {
        if (lines[i].time == lines[i + next].time) {
          lines[i].content += separator + lines[i + next].content;
          sameTimeLyricIndexes.add(i + next);

          next += 1;
        } else {
          i += next;

          next = 1;
        }
      } else {
        break;
      }
    }

    for (int i = sameTimeLyricIndexes.length - 1; i >= 0; i--) {
      lines.removeAt(sameTimeLyricIndexes[i]);
    }
  }

  ///将歌词拆分成两句相同时间戳的歌词
  ///before:
  ///[01:56.32]line1 [separator] line2
  ///after:
  ///[01:56.32]line1
  ///[01:56.32]line2
  void split({String separator = " | "}) {
    List<LrcCaptionLine> aboutToAdd = [];

    for (var element in lines) {
      var splitedLine = element.content.split(separator);
      if (splitedLine.length >= 2) {
        element.content = splitedLine[0];
        for (int i = 1; i < splitedLine.length; i++) {
          aboutToAdd.add(
            LrcCaptionLine(
              content: splitedLine[i],
              time: element.time,
            ),
          );
        }
      }
    }

    lines.addAll(aboutToAdd);
    stableSort();
  }

  int binarySearch(LrcCaptionLine item, int low, int high) {
    while (low <= high) {
      int mid = (low + (high - low) / 2).truncate();
      if (item.time == lines[mid].time) {
        return mid + 1;
      } else if (item.time > lines[mid].time) {
        low = mid + 1;
      } else if (item.time < lines[mid].time) {
        high = mid - 1;
      }
    }
    return low;
  }

  ///Binary Insertion Sort
  void stableSort() {
    bool needSort = false;
    for (int i = 0; i < lines.length - 1; i++) {
      if (lines[i].time != lines[i + 1].time) {
        needSort = true;
      }
    }
    if (needSort == true) {
      for (int i = 1; i < lines.length; i++) {
        int j = i - 1;
        var selected = lines[i];

        int loc = binarySearch(selected, 0, j);

        while (j >= loc) {
          lines[j + 1] = lines[j];
          j--;
        }
        lines[j + 1] = selected;
      }
    }
  }
}

class LrcCaptionLine {
  LrcCaptionLine({
    required this.content,
    required this.time,
  });

  String content;
  // int minute;
  // double second;
  Duration time;

  String toFormattedTime() {
    return time.toString().substring(
          time.toString().indexOf(":") + 1,
          time.toString().length - 4,
        );
  }

  static LrcCaptionLine? fromLrcLine({required String lrcLine}) {
    if (lrcLine.trim().isEmpty) {
      return null;
    }
    var lrcTimeString = lrcLine.substring(
      lrcLine.indexOf("[") + 1,
      lrcLine.indexOf("]"),
    );
    var content = lrcLine.substring(lrcLine.indexOf("]") + 1);
    var minute = int.tryParse(lrcTimeString.split(":")[0]);
    var second = double.tryParse(lrcTimeString.split(":")[1]);

    if (minute == null || second == null) {
      return null;
    }

    var inMilliseconds = ((minute * 60 + second) * 1000).toInt();

    return LrcCaptionLine(
      time: Duration(milliseconds: inMilliseconds),
      content: content,
    );
  }
}
