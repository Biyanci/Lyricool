import 'package:flutter/material.dart';

import '../model/caption.dart';

class DeleteCaptionView extends StatefulWidget {
  const DeleteCaptionView(
      {super.key, required this.deleteList, required this.caption});

  final List<bool> deleteList;
  final LrcCaption caption;

  @override
  State<DeleteCaptionView> createState() => _DeleteCaptionViewState();
}

class _DeleteCaptionViewState extends State<DeleteCaptionView> {
  bool isSelectAll = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            for (int i = 0; i < widget.caption.lines.length; i++) {
              widget.deleteList[i] = false;
            }
            Navigator.pop(context);
          },
        ),
        title: const Text("删除"),
        actions: [
          IconButton(
            onPressed: isSelectAll
                ? () {
                    for (int i = 0; i < widget.deleteList.length; i++) {
                      widget.deleteList[i] = false;
                    }
                    isSelectAll = false;
                    setState(() {});
                  }
                : () {
                    for (int i = 0; i < widget.deleteList.length; i++) {
                      widget.deleteList[i] = true;
                    }
                    isSelectAll = true;
                    setState(() {});
                  },
            icon: isSelectAll
                ? const Icon(Icons.deselect)
                : const Icon(Icons.select_all),
            tooltip: isSelectAll ? "取消全选" : "全选",
          ),
          const SizedBox(
            width: 8.0,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              //issue:can't delete captionLine correctly
              for (int i = widget.caption.lines.length - 1; i >= 0; i--) {
                if (widget.deleteList[i] == true) {
                  widget.caption.lines.removeAt(i);
                  widget.deleteList.removeAt(i);
                }
              }
              Navigator.pop(context);
            },
          ),
          const SizedBox(
            width: 8.0,
          )
        ],
      ),
      body: ListView.builder(
        itemCount: widget.caption.lines.length,
        itemBuilder: (context, index) {
          return ListTile(
            contentPadding: const EdgeInsets.only(left: 24.0, right: 8.0),
            mouseCursor: SystemMouseCursors.click,
            onTap: () {
              setState(() {
                widget.deleteList[index] = !widget.deleteList[index];
              });
            },
            leading: Text(index.toString()),
            title: Text(widget.caption.lines[index].content),
            trailing: SizedBox(
              width: 100.0,
              child: Row(
                children: [
                  Text(widget.caption.lines[index].toFormattedTime()),
                  const SizedBox(width: 8.0),
                  Checkbox(
                    value: widget.deleteList[index],
                    onChanged: (value) {
                      setState(() {
                        widget.deleteList[index] = !widget.deleteList[index];
                      });
                    },
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}