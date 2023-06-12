# Lyricool

基于Flutter的歌词制作工具

<img width="396" alt="image" src="https://github.com/Biyanci/Lyricool/assets/98510207/ad4d1026-4744-4368-8a59-9693bdcf55c6">

你可以通过以下四种方法开始编辑.lrc歌词文件：

## 从Bilibili获取视频字幕

##### 点击“导入Bilibili CC字幕”

##### 输入视频BV号，回车以搜索

<img width="396" alt="image" src="https://github.com/Biyanci/Lyricool/assets/98510207/3ae88c3f-5e1e-480e-9792-796c7c9111be">

##### 点击列出的项进入编辑界面，或是点击列表右侧的按钮查看字幕所有内容

## 从格式化的文本中获取歌词

##### 点击“导入格式化文本”

##### 输入歌词文件名和歌词。文本格式要求：一行一句歌词，允许空行。带有时间戳的.lrc文本内容请使用“打开歌词文件”功能导入

<img width="396" alt="image" src="https://github.com/Biyanci/Lyricool/assets/98510207/b4cb3415-77d4-47b3-a5c0-952557478582">

##### 点击右下角的按钮进入编辑界面。在这里，所有歌词的时间戳都被设定为[00:00.00]。你可以使用编辑页面的打轴功能来给每一行歌词设置时间轴

## 直接打开.lrc文件

##### 点击“打开文件”

##### 选择.lrc歌词文件即可进入编辑界面

<img width="552" alt="image" src="https://github.com/Biyanci/Lyricool/assets/98510207/31e2ec96-d9ba-48de-941f-237974a64abf">

.lrc歌词兼容情况：

1. 不支持[ar:], [by:]等标签，会直接忽略这些标签

2.  暂不支持逐字歌词

3.  保留只有时间戳没有内容的歌词

## 新建歌词文件

##### 点击“新建歌词文件”

##### 输入歌词文件名，确定后进入编辑界面

<img width="396" alt="image" src="https://github.com/Biyanci/Lyricool/assets/98510207/9363e920-65a1-452f-8135-c4e5059f1431">

## 编辑界面

<img width="396" alt="image" src="https://github.com/Biyanci/Lyricool/assets/98510207/0cec7494-cc6a-4a22-a25e-e50709485746">

包含以下功能：
1. 重命名歌词文件名
2. 修改歌词行（修改时间戳、内容。修改后不进行排序）
3. 添加歌词行（默认添加到末尾，给定位置时插入到指定位置。插入后不进行排序）
4. 选择歌词行删除（删除后不进行排序）
5. 预览歌词
6. 打轴（给每行歌词设置时间轴，打轴后不进行排序）
7. 合并相同时间戳的歌词行（进行排序以加快合并速度）
8. 拆分歌词行
9. 排序（所有时间戳相同时不排序。使用Binary Insertion Sort，不改变时间戳相同的几句歌词的相对位置，即保证稳定性。只有一句歌词时间戳大于零且其他歌词的时间戳均为零时会打乱顺序。请避免在这种情况下进行排序操作）
10. 调整时间轴。将所有歌词的时间轴提前或延后指定的一段时间（time + delay），不排序。若time + delay<0，则令 time = 0
11. 保存文件（输出目录：用户Document目录<img width="117" alt="image" src="https://github.com/Biyanci/Lyricool/assets/98510207/d2263a98-9c9b-4aa1-997b-a7c54001bae1">）

## 预览界面

<img width="396" alt="image" src="https://github.com/Biyanci/Lyricool/assets/98510207/81968d9b-866a-4f74-937e-7dab1229ee53">

点击播放按钮后，延时3s（默认值，可自定义）开始预览歌词

同时高亮显示时间戳相同的歌词并滚动到该行歌词（可能不会居中）

<img width="396" alt="image" src="https://github.com/Biyanci/Lyricool/assets/98510207/627d4227-a985-40ce-84e4-55a07d4ddeef">

预览时，可以暂停或重新预览歌词

##### 设置延时

点击按钮<img width="84" alt="image" src="https://github.com/Biyanci/Lyricool/assets/98510207/215d9b3a-e5de-4b49-a07c-88d2bd647ce9">

输入一个整数并保存，下一次播放时生效<img width="218" alt="屏幕截图 2023-06-11 214322" src="https://github.com/Biyanci/Lyricool/assets/98510207/e16251a7-3c63-4157-9465-b9935f48feac">

<img width="396" alt="image" src="https://github.com/Biyanci/Lyricool/assets/98510207/37103343-e07f-46c7-ad32-db03e9bb1897">

## 打轴界面

<img width="396" alt="image" src="https://github.com/Biyanci/Lyricool/assets/98510207/c513dbb3-b112-4d9e-b987-6c03b5d9038d">

点击开始按钮后，高亮显示要修改时间轴的歌词，点击按钮<img width="58" alt="image" src="https://github.com/Biyanci/Lyricool/assets/98510207/56169934-59bc-4c94-aa62-69b0ad1be0d1">，将当前时间戳赋给高亮显示的歌词

打轴时，可以暂停或重新开始

##### 设置延时

同预览界面

##### 设置同时修改几行歌词的时间戳

点击按钮<img width="69" alt="image" src="https://github.com/Biyanci/Lyricool/assets/98510207/bbbe009e-b010-4d20-b4a7-404109b051d9">并输入行数

<img width="224" alt="image" src="https://github.com/Biyanci/Lyricool/assets/98510207/3cd16466-e2a5-4364-9129-d5c072bb52a3">

<img width="396" alt="image" src="https://github.com/Biyanci/Lyricool/assets/98510207/ad4ac094-ef36-4797-b217-7006dce0a513">

高亮效果需要点击一次打轴按钮后才会生效，但实际上已经可以同时修改多行歌词的时间戳（即，修改是立即生效的）
