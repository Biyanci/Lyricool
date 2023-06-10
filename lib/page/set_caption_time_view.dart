import 'dart:async';

import 'package:caption_tool/color_schemes.g.dart';
import 'package:caption_tool/model/caption.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class SetCaptionTimeView extends StatelessWidget {
  const SetCaptionTimeView({super.key});

  @override
  Widget build(BuildContext context) {
    LrcCaption caption =
        ModalRoute.of(context)!.settings.arguments as LrcCaption;

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
    var ticker = Ticker(
      (elapsed) {
        currentDuration.value += elapsed - lastDuration;
        lastDuration = elapsed;
      },
    );

    double actionBarHeight = 192.0;
    var listViewHeight =
        MediaQuery.of(context).size.height - actionBarHeight - 96;

    var appBar = AppBar(
      title: const Text("预览"),
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
                  if (useDelay == true) {
                    currentDuration.value = const Duration(seconds: 3);
                    Timer.periodic(
                      const Duration(seconds: 1),
                      (timer) {
                        currentDuration.value -= const Duration(seconds: 1);
                        if (currentDuration.value == Duration.zero) {
                          ticker.start();
                          isPlay.value = true;
                          canReplay.value = true;
                          useDelay = false;
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
                    caption.lines[index.value].time = currentDuration.value;
                    // caption.lines[index.value + 1].time = currentDuration.value;
                    index.value += 1;
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
              child: ValueListenableBuilder(
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
                                color: (i == value)
                                    ? lightColorScheme.primary
                                    : Colors.grey,
                              ),
                            ),
                            title: Center(
                              child: Text(
                                caption.lines[i].content,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: (i == value)
                                        ? lightColorScheme.primary
                                        : Colors.grey,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                            trailing: Text(
                              caption.lines[i].toFormattedTime(),
                              style: TextStyle(
                                  color: (i == value)
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
              ),
            ),
            SizedBox(
              height: actionBarHeight,
              width: MediaQuery.of(context).size.width,
              child: Column(
                children: [
                  tickerStr,
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
                  timerBtn
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
