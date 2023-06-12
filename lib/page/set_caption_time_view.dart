import 'dart:async';

import 'package:caption_tool/color_schemes.g.dart';
import 'package:caption_tool/model/caption.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

class SetCaptionTimeView extends StatelessWidget {
  const SetCaptionTimeView({super.key, required this.caption});
  final LrcCaption caption;
  @override
  Widget build(BuildContext context) {

    var scrollController = ScrollController();

    ///当前时间
    var currentDuration = ValueNotifier(Duration.zero);

    ///上一个elapsed
    var lastDuration = Duration.zero;

    ///当前歌词的序号
    var index = ValueNotifier(0);

    var isPlay = ValueNotifier(false);
    var canReplay = ValueNotifier(false);
    var useDelay = true;
    var isDelaying = false;
    var delayDuration = ValueNotifier(const Duration(seconds: 3));
    var ticker = Ticker(
      (elapsed) {
        currentDuration.value += elapsed - lastDuration;
        lastDuration = elapsed;
      },
    );

    var setTimeCount = ValueNotifier(1);

    double actionBarHeight = 228.0;
    var listViewHeight =
        MediaQuery.of(context).size.height - actionBarHeight - 96;

    var appBar = AppBar(
      title: const Text("打轴"),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (ticker.isTicking) {
            ticker.dispose();
          }
          Navigator.pop(context);
        },
      ),
    );

    var tickerStr = ValueListenableBuilder(
      valueListenable: currentDuration,
      builder: (context, value, child) {
        return Text(
          value.toString().substring(
                value.toString().indexOf(":") + 1,
                value.toString().length - 4,
              ),
          style: const TextStyle(fontSize: 22.0),
        );
      },
    );

    var replayBtn = ValueListenableBuilder(
      valueListenable: canReplay,
      builder: (context, value, child) {
        return IconButton.filled(
          constraints: const BoxConstraints(minWidth: 64.0, minHeight: 64.0),
          onPressed: value
              ? () {
                  ticker.stop();
                  index.value = 0;
                  lastDuration = Duration.zero;
                  currentDuration.value = Duration.zero;
                  scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.ease,
                  );
                  isPlay.value = false;
                  canReplay.value = false;
                  useDelay = true;
                  scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.ease,
                  );
                }
              : null,
          icon: const Icon(Icons.replay),
        );
      },
    );

    var playORpauseBtn = ValueListenableBuilder(
      valueListenable: isPlay,
      builder: (context, value, child) {
        return IconButton.filled(
          constraints: const BoxConstraints(minWidth: 64.0, minHeight: 64.0),
          onPressed: value
              ? () {
                  ticker.stop();
                  lastDuration = Duration.zero;
                  isPlay.value = false;
                }
              : () async {
                  if (isDelaying) {
                  } else if (useDelay == true) {
                    currentDuration.value = delayDuration.value;
                    isDelaying = true;
                    Timer.periodic(
                      const Duration(seconds: 1),
                      (timer) {
                        currentDuration.value -= const Duration(seconds: 1);
                        if (currentDuration.value == Duration.zero) {
                          ticker.start();
                          isPlay.value = true;
                          canReplay.value = true;
                          useDelay = false;
                          isDelaying = false;
                          timer.cancel();
                        }
                      },
                    );
                  } else if (useDelay == false) {
                    ticker.start();
                    isPlay.value = true;
                    canReplay.value = true;
                  }
                },
          icon: value ? const Icon(Icons.pause) : const Icon(Icons.play_arrow),
        );
      },
    );

    var timerBtn = ValueListenableBuilder(
      valueListenable: isPlay,
      builder: (context, value, child) {
        return IconButton.filled(
          constraints: const BoxConstraints(minWidth: 64.0, minHeight: 64.0),
          onPressed: value
              ? () {
                  if (index.value < caption.lines.length) {
                    for (int i = 0; i < setTimeCount.value; i++) {
                      caption.lines[index.value].time = currentDuration.value;
                      index.value += 1;
                    }
                  }

                  scrollController.animateTo(
                    (index.value * 72.0) + 72.0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.ease,
                  );
                }
              : null,
          icon: const Icon(Icons.timer),
        );
      },
    );

    var setDelayBtn = ValueListenableBuilder(
      valueListenable: delayDuration,
      builder: (context, value, child) {
        return SizedBox(
          width: 100.0,
          child: ElevatedButton.icon(
            onPressed: () async {
              String newDelayStr = await showDialog(
                context: context,
                builder: (context) {
                  var delayEditingController = TextEditingController(
                      text: delayDuration.value.inSeconds.toString());
                  return SimpleDialog(
                    contentPadding:
                        const EdgeInsets.fromLTRB(24.0, 12.0, 24.0, 16.0),
                    title: const Text("延时"),
                    children: [
                      const Text("开始预览的延时，默认3s"),
                      const SizedBox(height: 16.0),
                      TextField(
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        controller: delayEditingController,
                        decoration: const InputDecoration(
                          labelText: "延时",
                          suffixText: "s",
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
                              Navigator.pop<String>(
                                context,
                                delayEditingController.text,
                              );
                            },
                            child: const Text("确认"),
                          ),
                        ],
                      )
                    ],
                  );
                },
              );

              var newDelayInseconds = int.tryParse(newDelayStr);
              if (newDelayInseconds != null) {
                delayDuration.value = Duration(seconds: newDelayInseconds);
              }
            },
            label: Text("+ ${delayDuration.value.inSeconds}s"),
            icon: const Icon(Icons.more_time),
          ),
        );
      },
    );

    var lyricView = ValueListenableBuilder(
      valueListenable: index,
      builder: (context, value, child) {
        return ListView(
          controller: scrollController,
          children: [
            SizedBox(
              height: listViewHeight / 2,
            ),
            for (int i = 0; i < caption.lines.length; i++)
              SizedBox(
                height: 72.0,
                child: ListTile(
                  leading: Text(
                    "$i",
                    style: TextStyle(
                      color:
                          (i - value >= 0) && (i - value < setTimeCount.value)
                              ? lightColorScheme.primary
                              : Colors.grey,
                    ),
                  ),
                  title: Center(
                    child: Text(
                      caption.lines[i].content,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: (i - value >= 0) &&
                                  (i - value < setTimeCount.value)
                              ? lightColorScheme.primary
                              : Colors.grey,
                          fontSize: 20,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  trailing: Text(
                    caption.lines[i].toFormattedTime(),
                    style: TextStyle(
                        color:
                            (i - value >= 0) && (i - value < setTimeCount.value)
                                ? lightColorScheme.primary
                                : Colors.grey),
                  ),
                ),
              ),
            SizedBox(
              height: listViewHeight / 2,
            ),
          ],
        );
      },
    );
    var setTimeCountBtn = ValueListenableBuilder(
      valueListenable: setTimeCount,
      builder: (context, value, child) {
        return ElevatedButton.icon(
          onPressed: () async {
            String newSetTimeCountStr = await showDialog(
              context: context,
              builder: (context) {
                var setTimeCountEditingController =
                    TextEditingController(text: setTimeCount.value.toString());
                return SimpleDialog(
                  contentPadding:
                      const EdgeInsets.fromLTRB(24.0, 12.0, 24.0, 16.0),
                  title: const Text("同时打轴"),
                  children: [
                    const Text("同时修改多行歌词的时间戳"),
                    const SizedBox(height: 16.0),
                    TextField(
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      controller: setTimeCountEditingController,
                      decoration: const InputDecoration(
                        labelText: "行数",
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
                            Navigator.pop<String>(
                              context,
                              setTimeCountEditingController.text,
                            );
                          },
                          child: const Text("确认"),
                        ),
                      ],
                    )
                  ],
                );
              },
            );

            var newSetTimeCount = int.tryParse(newSetTimeCountStr);
            if (newSetTimeCount != null) {
              setTimeCount.value = newSetTimeCount;
            }
          },
          icon: const Icon(Icons.timer),
          label: Text("* ${setTimeCount.value}"),
        );
      },
    );
    return WillPopScope(
      onWillPop: () {
        ticker.dispose();
        scrollController.dispose();
        return Future.value(true);
      },
      child: Scaffold(
        appBar: appBar,
        body: Column(
          children: [
            SizedBox(
              height: listViewHeight,
              child: lyricView,
            ),
            SizedBox(
              height: actionBarHeight,
              width: MediaQuery.of(context).size.width,
              child: Column(
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.5 - 41,
                      ),
                      tickerStr,
                      const SizedBox(width: 12.0),
                      setDelayBtn,
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      replayBtn,
                      const SizedBox(
                        width: 16.0,
                      ),
                      playORpauseBtn
                    ],
                  ),
                  Row(
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.5 - 32,
                      ),
                      timerBtn,
                      const SizedBox(width: 30.0),
                      setTimeCountBtn
                    ],
                  ),
                  const SizedBox(height: 36.0),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
