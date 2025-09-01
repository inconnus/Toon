import 'dart:collection';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fullscreen/flutter_fullscreen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import 'package:shared_preferences/shared_preferences.dart';

const List<String> list = <String>['EP 1', 'ตอนที่ 2', 'ตอนที่ 3', 'ตอนที่ 4', 'ตอนที่ 5', 'ตอนที่ 6', 'ตอนที่ 7', 'ตอนที่ 8'];

class ContentsModel {
  final int episodeCount;
  final int pageCount;
  ContentsModel({required this.episodeCount, required this.pageCount});
}

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _State();
}

class _State extends ConsumerState<HomePage> {
  late PageController _pageController;
  late TextEditingController _dropdownController;
  // int episodeCount = 0;
  List<int> pageCounts = [];

  int _currentEpisode = 1;
  bool _showMenu = false;
  // double _savedOffset = 0;
  bool _isDragging = false;
  // List<String> _episodes = [];
  // Map<String, int> _pages = {};
  @override
  void initState() {
    print("loadEpisodes");
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadEpisodes();
    });

    _pageController = PageController();
    _dropdownController = TextEditingController();
    // _pageController.addListener(() async {
    //   final page = _pageController.page ?? 0;
    //   final dragging = page % 1 != 0;

    //   if (dragging != _isDragging) {
    //     if (dragging) {
    //       setState(() => _isDragging = dragging);
    //     } else {
    //       await Future.delayed(const Duration(milliseconds: 300));
    //       setState(() => _isDragging = dragging);
    //     }
    //   }
    // });

    // // เมื่อ scroll เปลี่ยน → save ค่า
    // _controller.addListener(() {
    //   print(_controller.offset);
    //   _saveScrollOffset(_controller.offset);
    // });
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   _loadScrollOffset();
    // });
    super.initState();
  }

  void loadEpisodes() async {
    // ดึงรายชื่อโฟลเดอร์ตอน
    final epc = await fetchFiles("http://192.168.0.3:8080/Toon/Disastrous%20Necromancer/");
    print("epc $epc");

    // print("Episodes ${episodes}");
    // setState(() => episodeCount = epc);

    // ดึงไฟล์แต่ละตอน
    final temp = <int>[];
    for (var ep = 1; ep <= epc; ep++) {
      // print(ep);
      // print("http://192.168.0.3:8080/Toon/Disastrous%20Necromancer/ep-$ep/");
      final pages = await fetchFiles("http://192.168.0.3:8080/Toon/Disastrous%20Necromancer/ep-$ep/");
      temp.add(pages);
      // setState(() => _pages.add(pages));
      // print("Episode $ep -> $pages");

      // เก็บผลลัพธ์ใน state
      // setState(() => _pages[ep] = pages);\
      // print("Episode $ep -> ${pages.length}");
    }
    setState(() => pageCounts = temp);
    //  if (!mounted) return;
    //  print(temp);
    // setState(() => _pages = temp);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int? episode = prefs.getInt('episode');
    if (episode != null) {
      setState(() => _currentEpisode = episode);
      _pageController.jumpToPage(episode - 1);
    }
  }

  Future<int> fetchFiles(String baseUrl) async {
    final res = await http.get(Uri.parse(baseUrl));
    if (res.statusCode == 200) {
      final doc = html.parse(res.body);
      final links = doc.querySelectorAll("a");
      // print("links $links");
      // return links.length;
      return links.map((e) => e.attributes['href'] ?? "").where((f) => f.isNotEmpty && f != "../" && f != ".DS_Store").toList().length;
    } else {
      throw Exception("Failed to load directory list");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GestureDetector(
            onTap: () {
              setState(() => _showMenu = !_showMenu);
            },
            child: PageView.builder(
              itemCount: pageCounts.length,
              controller: _pageController,
              onPageChanged: (value) async {
                setState(() {
                  _currentEpisode = value + 1;
                });
                _dropdownController.text = (value + 1).toString();
                final SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.setInt('episode', value + 1);
              },
              // itemBuilder: (context, pageIndex) =>
              // Row(children: [Text("${pageIndex + 1}"), Text("${_episodes[pageIndex]}"), Text("${_pages[_episodes[pageIndex]]}")]),
              itemBuilder: (context, pageIndex) => EpisodePage(
                // episode: _episodes[pageIndex],
                pageCount: pageCounts[pageIndex],
                pageIndex: pageIndex,
                isDragging: _isDragging,
              ),
            ),
          ),
          if (_showMenu)
            Positioned(
              left: 0,
              right: 0,
              bottom: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(40),
                          color: const Color.fromARGB(156, 255, 255, 255),
                          border: Border.all(color: const Color.fromARGB(255, 231, 231, 231)),
                        ),
                        child: Center(
                          child: DropdownMenuExample(
                            length: pageCounts.length,
                            onChanged: (value) {
                              setState(() {
                                _currentEpisode = int.parse(value);
                              });
                              _pageController.jumpToPage(int.parse(value) - 1);
                            },
                            controller: _dropdownController,
                            value: _currentEpisode.toString(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class EpisodePage extends ConsumerStatefulWidget {
  final int pageCount;
  final int pageIndex;
  final bool isDragging;
  const EpisodePage({super.key, required this.pageCount, required this.pageIndex, required this.isDragging});

  @override
  ConsumerState<EpisodePage> createState() => _EpisodePageState();
}

class _EpisodePageState extends ConsumerState<EpisodePage> with AutomaticKeepAliveClientMixin {
  int _retry = 0;

  void _scheduleRetry(String url) {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        print("retry $_retry $url");
        setState(() {
          _retry++;
        });
      }
    });
  }

  @override
  bool get wantKeepAlive => true; // ✅ keep state ไว้

  @override
  Widget build(BuildContext context) {
    super.build(context); // ต้องเรียก

    return Stack(
      children: [
        MediaQuery.removePadding(
          context: context,
          removeTop: true,
          removeBottom: true,
          child: ListView.builder(
            padding: EdgeInsets.zero,
            key: PageStorageKey('page_${widget.pageIndex + 1}'),
            cacheExtent: 10,
            itemCount: widget.pageCount,
            itemBuilder: (context, index) {
              // print('http://192.168.0.3:8080/Toon/Disastrous%20Necromancer/ep-${widget.pageIndex + 1}/page_${index + 1}.jpg');
              // return Image.network('http://192.168.0.3:8080/Toon/Disastrous%20Necromancer/ep-${pageIndex + 1}/page_2.jpg');
              // return Text("http://192.168.0.3:8080/Toon/Disastrous%20Necromancer/ep-${widget.pageIndex + 1}/page_${index + 1}.jpg");
              return Align(
                alignment: Alignment.topCenter,
                child: CachedNetworkImage(
                  imageUrl: "http://192.168.0.3:8080/Toon/Disastrous%20Necromancer/ep-${widget.pageIndex + 1}/page_${index + 1}.jpg",
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                  placeholder: (context, url) => Center(child: SizedBox(width: 30, height: 30, child: CircularProgressIndicator())),
                  errorWidget: (context, url, error) {
                    return Text("http://192.168.0.3:8080/Toon/Disastrous%20Necromancer/ep-${widget.pageIndex + 1}/page_${index + 1}.jpg");
                  },
                  // errorWidget: (context, url, error) => Icon(Icons.error),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class DropdownMenuExample extends StatefulWidget {
  final int length;
  final Function(String) onChanged;
  final String value;
  final TextEditingController controller;
  const DropdownMenuExample({super.key, required this.length, required this.onChanged, required this.value, required this.controller});

  @override
  State<DropdownMenuExample> createState() => _DropdownMenuExampleState();
}

typedef MenuEntry = DropdownMenuEntry<String>;

class _DropdownMenuExampleState extends State<DropdownMenuExample> {
  late List<MenuEntry> menuEntries;

  @override
  void initState() {
    super.initState();
    menuEntries = UnmodifiableListView<MenuEntry>(
      List.generate(widget.length, (index) => MenuEntry(value: (index + 1).toString(), label: (index + 1).toString())),
    );
    print("widget.value ${widget.value}");
    // print(menuEntries);
    widget.controller.text = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return DropdownMenu<String>(
      initialSelection: widget.value,
      controller: widget.controller,

      enableFilter: false,
      requestFocusOnTap: false,
      menuHeight: 670,
      width: 100,
      textAlign: TextAlign.center,
      showTrailingIcon: false,
      textStyle: TextStyle(fontSize: 14, color: const Color.fromARGB(255, 142, 142, 142)),
      inputDecorationTheme: InputDecorationTheme(
        contentPadding: EdgeInsets.symmetric(vertical: 8),
        isDense: true,

        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(40), borderSide: BorderSide.none),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(40),
          borderSide: BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(40), borderSide: BorderSide.none),
      ),

      menuStyle: MenuStyle(
        backgroundColor: WidgetStateProperty.all(Colors.white),
        shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
        elevation: WidgetStateProperty.all(5),
        shadowColor: WidgetStateProperty.all(const Color.fromARGB(107, 0, 0, 0)),
        visualDensity: VisualDensity.compact,
      ),
      onSelected: (String? value) {
        // This is called when the user selects an item.
        widget.onChanged(value!);
      },
      dropdownMenuEntries: menuEntries,
    );
  }
}
