import 'package:fl_lib/fl_lib.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toolbox/core/extension/context/locale.dart';
import 'package:toolbox/core/route.dart';
import 'package:toolbox/data/model/server/server_private_info.dart';
import 'package:toolbox/data/provider/server.dart';
import 'package:toolbox/data/res/provider.dart';
import 'package:toolbox/view/page/ssh/page.dart';

class SSHTabPage extends StatefulWidget {
  const SSHTabPage({super.key});

  @override
  State<SSHTabPage> createState() => _SSHTabPageState();
}

typedef _TabMap = Map<String, ({Widget page, GlobalKey<SSHPageState>? key})>;

class _SSHTabPageState extends State<SSHTabPage>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final _TabMap _tabMap = {
    l10n.add: (page: _buildAddPage(), key: null),
  };
  final _pageCtrl = PageController();
  final _fabVN = 0.vn;
  final _tabRN = RNode();

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: PreferredSizeListenBuilder(
        listenable: _tabRN,
        builder: () {
          return _TabBar(
            idxVN: _fabVN,
            map: _tabMap,
            onTap: _onTapTab,
            onClose: _onTapClose,
          );
        },
      ),
      body: _buildBody(),
      floatingActionButton: ListenableBuilder(
        listenable: _fabVN,
        builder: (_, __) {
          if (_fabVN.value != 0) return const SizedBox();
          return FloatingActionButton(
            heroTag: 'sshAddServer',
            onPressed: () => AppRoutes.serverEdit().go(context),
            tooltip: l10n.addAServer,
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }

  void _onTapTab(int idx) async {
    await _toPage(idx);
    _fabVN.value = idx;
    FocusScope.of(context).unfocus();
  }

  void _onTapClose(String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.attention),
          content: Text('${l10n.close} SSH ${l10n.conn}($name) ?'),
          actions: [
            TextButton(
              onPressed: () => context.pop(true),
              child: Text(l10n.ok, style: UIs.textRed),
            ),
            TextButton(
              onPressed: () => context.pop(false),
              child: Text(l10n.cancel),
            ),
          ],
        );
      },
    );
    Future.delayed(Durations.short1, FocusScope.of(context).unfocus);
    if (confirm != true) return;

    final item = _tabMap.remove(name);
    print(item?.key?.currentState);
    _tabRN.build();
  }

  Widget _buildAddPage() {
    return Center(
      child: Consumer<ServerProvider>(builder: (_, pro, __) {
        if (pro.serverOrder.isEmpty) {
          return Center(
            child: Text(
              l10n.serverTabEmpty,
              textAlign: TextAlign.center,
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(7),
          itemBuilder: (_, idx) {
            final spi = Pros.server.pick(id: pro.serverOrder[idx])?.spi;
            if (spi == null) return UIs.placeholder;
            return CardX(
              child: ListTile(
                title: Text(spi.name),
                subtitle: Text(spi.id, style: UIs.textGrey),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _onTapInitCard(spi),
              ),
            );
          },
          itemCount: pro.servers.length,
        );
      }),
    );
  }

  Widget _buildBody() {
    return ListenBuilder(
      listenable: _tabRN,
      builder: () {
        return PageView.builder(
          physics: const NeverScrollableScrollPhysics(),
          controller: _pageCtrl,
          itemCount: _tabMap.length,
          itemBuilder: (_, idx) {
            final name = _tabMap.keys.elementAt(idx);
            return _tabMap[name]?.page ?? UIs.placeholder;
          },
        );
      },
    );
  }

  void _onTapInitCard(ServerPrivateInfo spi) async {
    final name = () {
      final reg = RegExp(r'\((\d+)\)');
      final idxs = _tabMap.keys.map((e) => reg.firstMatch(e)).toList();
      final biggest = idxs
          .map((e) => e?.group(1))
          .where((e) => e != null)
          .reduce((a, b) => a!.length > b!.length ? a : b);
      final biggestInt = int.tryParse(biggest ?? '0');
      if (biggestInt != null && biggestInt > 0) {
        return '${spi.name}(${biggestInt + 1})';
      }
      return spi.name;
    }();
    final key = GlobalKey<SSHPageState>();
    _tabMap[name] = (
      page: SSHPage(
        // Keep it, or the Flutter will works unexpectedly
        key: key,
        spi: spi,
        notFromTab: false,
        onSessionEnd: () {
          _tabMap.remove(name);
        },
      ),
      key: key,
    );
    final idx = _tabMap.keys.toList().indexOf(name);
    _tabRN.build();
    await _toPage(idx);
    _fabVN.value = idx;
  }

  Future<void> _toPage(int idx) => _pageCtrl.animateToPage(idx,
      duration: Durations.short3, curve: Curves.fastEaseInToSlowEaseOut);

  @override
  bool get wantKeepAlive => true;
}

final class _TabBar extends StatelessWidget implements PreferredSizeWidget {
  const _TabBar({
    required this.idxVN,
    required this.map,
    required this.onTap,
    required this.onClose,
  });

  final ValueNotifier<int> idxVN;
  final _TabMap map;
  final void Function(int idx) onTap;
  final void Function(String name) onClose;

  List<String> get names => map.keys.toList();

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    return ListenBuilder(
      listenable: idxVN,
      builder: () {
        return ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
          itemCount: names.length,
          itemBuilder: (_, idx) => _buillItem(idx),
        );
      },
    );
  }

  Widget _buillItem(int idx) {
    final name = names[idx];
    return InkWell(
      borderRadius: BorderRadius.circular(13),
      onTap: () => onTap(idx),
      child: SizedBox(
        width: idx == 0 ? 80 : 130,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: idx == 0 ? 35 : 85,
              child: Text(name),
            ),
            if (idxVN.value == idx && idx != 0) FadeIn(child: UIs.dot()),
            idx == 0
                // Use [IconBtn] for same size
                ? IconBtn(icon: Icons.add, onTap: () {})
                : IconBtn(
                    icon: Icons.close,
                    onTap: () => onClose(name),
                  ),
          ],
        ),
      ).paddingOnly(left: 17, right: 3),
    ).paddingSymmetric(horizontal: 3);
  }
}
