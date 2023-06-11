import 'dart:convert';

import 'package:caption_tool/color_schemes.g.dart';
import 'package:caption_tool/model/caption.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

Future<BilibiliVideo?> getVideoDetail(String bvID) async {
  var getVideoDetailUrl = Uri.https(
    "api.bilibili.com",
    "x/web-interface/view",
    {"bvid": bvID},
  );

  var videoDetailResponse = await http.get(getVideoDetailUrl);

  var videoDetailMap =
      json.decode(const Utf8Decoder().convert(videoDetailResponse.bodyBytes));

  var videoTitle = videoDetailMap?["data"]?["title"];
  var videoCover = videoDetailMap?["data"]?["pic"];
  var videoDescribe = videoDetailMap?["data"]?["desc"];

  List<Map<String, dynamic>> videoCaptionMapList = [];

  List videoCaptionList = videoDetailMap?["data"]?["subtitle"]?["list"] ?? [];

  for (int i = 0; i < videoCaptionList.length; i++) {
    var getCaptionUrl = Uri.parse(videoCaptionList[i]["subtitle_url"]);
    var captionResponse = await http.get(getCaptionUrl);
    videoCaptionMapList.add(
        json.decode(const Utf8Decoder().convert(captionResponse.bodyBytes)));
  }
  if (videoTitle == null) {
    return null;
  }

  return BilibiliVideo(
    title: videoTitle,
    describe: videoDescribe,
    cover: Image.network(videoCover),
    captionList: videoCaptionMapList,
  );
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  BilibiliVideo? bilibiliVideo;
  var bvIDEditingController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    var searchCaptionBar = TextField(
      controller: bvIDEditingController,
      onSubmitted: (value) async {
        bilibiliVideo = await getVideoDetail(value);
        if (bilibiliVideo == null) {
          if (context.mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text("不正确的BV号")));
          }
        } else if (bilibiliVideo!.captionList.isEmpty) {
          if (context.mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text("该视频下没有CC字幕")));
          }
        }

        setState(() {});
      },
      decoration: InputDecoration(
        constraints: const BoxConstraints(maxHeight: 56.0),
        labelText: "BV号",
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: IconButton(
            onPressed: () async {
              bilibiliVideo = await getVideoDetail(bvIDEditingController.text);
              if (bilibiliVideo == null) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text("不正确的BV号")));
                }
              } else if (bilibiliVideo!.captionList.isEmpty) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("该视频下没有CC字幕")));
                }
              }

              setState(() {});
            },
            icon: const Icon(Icons.search),
          ),
        ),
        border: const OutlineInputBorder(),
      ),
    );

    List<Widget> videoInfo = <Widget>[
      searchCaptionBar,
      const SizedBox(height: 16.0),
    ];
    if (bilibiliVideo == null) {
      videoInfo = <Widget>[
        searchCaptionBar,
        const SizedBox(height: 16.0),
      ];
    } else if (bilibiliVideo!.captionList.isEmpty) {
      videoInfo = [
        searchCaptionBar,
        const SizedBox(height: 16.0),
        SizedBox(
          height: 156.0,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("标题：\n${bilibiliVideo!.title}"),
                    const SizedBox(height: 8.0),
                    Text(
                      "简介：\n${bilibiliVideo!.describe}",
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16.0),
              Expanded(child: bilibiliVideo!.cover),
            ],
          ),
        ),
      ];
    } else if (bilibiliVideo!.captionList.isNotEmpty) {
      videoInfo = [
        searchCaptionBar,
        const SizedBox(height: 16.0),
        SizedBox(
          height: 200.0,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "标题：",
                      style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w600,
                          color: lightColorScheme.primary),
                    ),
                    SizedBox(
                      height: 64,
                      child: Text(bilibiliVideo!.title),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      "简介：",
                      style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w600,
                          color: lightColorScheme.primary),
                    ),
                    SizedBox(
                      height: 64,
                      child: Text(
                        bilibiliVideo!.describe,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16.0),
              Expanded(child: bilibiliVideo!.cover),
            ],
          ),
        ),
        const SizedBox(height: 16.0),
        Text(
          "CC字幕：",
          style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.w600,
              color: lightColorScheme.primary),
        ),
        SizedBox(
          height: MediaQuery.of(context).size.height - 440,
          child: ListView.builder(
            itemCount: bilibiliVideo!.captionList.length,
            itemBuilder: (context, index) {
              return CaptionListTile(
                  title: bilibiliVideo!.title,
                  captionRawList: bilibiliVideo!.captionList[index]["body"]);
            },
          ),
        ),
      ];
    }

    return Scaffold(
      appBar: AppBar(title: const Text("搜索")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: videoInfo,
        ),
      ),
    );
  }
}

class CaptionListTile extends StatelessWidget {
  const CaptionListTile({
    super.key,
    required this.title,
    required this.captionRawList,
  });
  final String title;
  final List captionRawList;

  @override
  Widget build(BuildContext context) {
    var from_1 = captionRawList[0]["from"];
    var to_1 = captionRawList[0]["to"];
    var content_1 = captionRawList[0]["content"];
    var from_2 = captionRawList[2]["from"];
    var to_2 = captionRawList[1]["to"];
    var content_2 = captionRawList[1]["content"];

    var captionOverview = SizedBox(
      width: 200.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("${from_1}s -> ${to_1}s"),
          Text(
            content_1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8.0),
          Text("${from_2}s -> ${to_2}s"),
          Text(
            content_2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          var lyric = LrcCaption.fromJsonMap(
              title: title, captionRawList: captionRawList);
          Navigator.pushNamed(
            context,
            "CaptionEditingPage",
            arguments: lyric,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              captionOverview,
              IconButton(
                tooltip: "展开",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return CaptionDetailView(
                          captionRawList: captionRawList,
                        );
                      },
                    ),
                  );
                },
                icon: const Icon(Icons.fullscreen),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CaptionDetailView extends StatelessWidget {
  const CaptionDetailView({super.key, required this.captionRawList});
  final List captionRawList;

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
        title: const Text("详情"),
      ),
      body: ListView.builder(
        itemCount: captionRawList.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(
                "${captionRawList[index]["from"]}s -> ${captionRawList[index]["to"]}s"),
            subtitle: Text(captionRawList[index]["content"]),
          );
        },
      ),
    );
  }
}
