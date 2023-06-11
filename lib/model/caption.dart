// ignore_for_file: no_leading_underscores_for_local_identifiers
import 'dart:io';

import 'package:flutter/material.dart';

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
    lrcCaption.lines.sort(
      (a, b) => a.time.compareTo(b.time),
    );

    return lrcCaption;
  }

  ///合并相同时间戳的歌词
  ///before:
  ///[01:56.32]line1
  ///[01:56.32]line2
  ///after:
  ///[01:56.32]line1 [separator] line2
  void mergeSameTimeLines({String separator = " | "}) {
    lines.sort((a, b) => a.time.compareTo(b.time));

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
    lines.sort((a, b) => a.time.compareTo(b.time));
  }

  List<int> sameTimeCounts() {
    lines.sort((a, b) => a.time.compareTo(b.time));
    int count = 1;

    List<int> sameTimeCounts = [];

    for (int i = 0; i < lines.length - 1; i++) {
      if (lines[i].time == lines[i + 1].time) {
        count += 1;
      } else {
        for (int j = 0; j < count; j++) {
          sameTimeCounts.add(count);
        }

        count = 1;
        continue;
      }
    }

    return sameTimeCounts;
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
