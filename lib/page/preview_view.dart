import 'dart:async';

import 'package:caption_tool/color_schemes.g.dart';
import 'package:caption_tool/model/caption.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class PreviewView extends StatefulWidget {
  const PreviewView(
      {super.key, required this.source, required this.globalKeys});

  final LrcCaption source;
  final List<GlobalKey> globalKeys;

  @override
  State<PreviewView> createState() => _PreviewViewState();
}

class _PreviewViewState extends State<PreviewView> {
  var scrollController = ScrollController();

  double actionBarHeight = 192.0;

  List<double> listTileHeight = [];

  ///当前时间
  var currentDuration = ValueNotifier(Duration.zero);

  ///上一个elapsed
  var lastElapsed = Duration.zero;

  ///当前歌词的序号
  var index = ValueNotifier(0);

  var isPlay = ValueNotifier(false);
  var canReplay = ValueNotifier(false);
  var useDelay = true;

  Ticker ticker = Ticker((elapsed) {});

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      for (int i = 0; i < widget.source.lines.length; i++) {
        final height = widget.globalKeys[i].currentContext!.size!.height;

        listTileHeight.add(height);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var listViewHeight =
        MediaQuery.of(context).size.height - actionBarHeight - 96;
    double offset = listViewHeight / 4;

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
                  lastElapsed = Duration.zero;
                  currentDuration.value = Duration.zero;
                  scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.ease,
                  );
                  isPlay.value = false;
                  canReplay.value = false;
                  useDelay = true;
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
                  lastElapsed = Duration.zero;
                  isPlay.value = false;
                }
              : () async {
                  if (useDelay == true) {
                    ticker = Ticker(
                      (elapsed) {
                        currentDuration.value += elapsed - lastElapsed;
                        lastElapsed = elapsed;
                        if (index.value < widget.source.lines.length) {
                          if (currentDuration.value >=
                              widget.source.lines[index.value].time) {
                            scrollController.animateTo(
                              offset,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.ease,
                            );

                            index.value += 1;
                            if (index.value >= widget.source.lines.length) {
                              offset += listTileHeight.last;
                            } else {
                              offset += listTileHeight[index.value];
                            }
                          }
                        }
                      },
                    );
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
                  return SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      children: [
                        SizedBox(height: listViewHeight / 2),
                        for (int i = 0; i < widget.source.lines.length; i++)
                          ListTile(
                            key: widget.globalKeys[i],
                            leading: Text(
                              "$i",
                              style: TextStyle(
                                color: (i + 1 == index.value)
                                    ? lightColorScheme.primary
                                    : Colors.grey,
                              ),
                            ),
                            title: Center(
                              child: Text(
                                widget.source.lines[i].content,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: (i + 1 == index.value)
                                      ? lightColorScheme.primary
                                      : Colors.grey,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            trailing: Text(
                              widget.source.lines[i].toFormattedTime(),
                              style: TextStyle(
                                color: (i + 1 == index.value)
                                    ? lightColorScheme.primary
                                    : Colors.grey,
                              ),
                            ),
                          ),
                        SizedBox(
                          height: listViewHeight / 2,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              height: actionBarHeight,
              width: MediaQuery.of(context).size.width,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  tickerStr,
                  const SizedBox(height: 16.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      replayBtn,
                      const SizedBox(width: 16.0),
                      playORpauseBtn
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
