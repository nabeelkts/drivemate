import 'package:flutter/material.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.0,
        leading: IconButton(
          color: Colors.black,
          icon: const Icon(Icons.menu),
          iconSize: 28.0,
          onPressed: () {},
        ),
        actions: <Widget>[
          IconButton(
            color: Colors.black,
            icon: const Icon(Icons.notifications_none),
            iconSize: 28.0,
            onPressed: () {},
          ),
        ],
      ),
      //     body: CustomScrollView(
      //       physics: const ClampingScrollPhysics(),
      //       slivers: <Widget>[
      //         _buildHeader(),
      //         _buildRegionTabBar(),
      //         _buildStatsTabBar(),
      //         const SliverPadding(
      //           padding: EdgeInsets.symmetric(horizontal: 10.0),
      //           sliver: SliverToBoxAdapter(
      //             child: StatsGrid(),
      //           ),
      //         ),
      //       ],
      //     ),
      //   );
      // }

      // SliverPadding _buildHeader() {
      //   return const SliverPadding(
      //     padding: EdgeInsets.all(20.0),
      //     sliver: SliverToBoxAdapter(
      //       child: Text(
      //         'Statistics',
      //         style: TextStyle(
      //           color: Colors.black,
      //           fontSize: 20,
      //           fontWeight: FontWeight.bold,
      //         ),
      //       ),
      //     ),
      //   );
      // }

      // SliverToBoxAdapter _buildRegionTabBar() {
      //   return SliverToBoxAdapter(
      //     child: DefaultTabController(
      //       length: 2,
      //       child: Container(
      //         margin: const EdgeInsets.symmetric(horizontal: 20.0),
      //         height: 40.0,
      //         decoration: BoxDecoration(
      //           color: Colors.black26,
      //           borderRadius: BorderRadius.circular(25.0),
      //         ),
      //         child: TabBar(
      //           indicator: const BubbleTabIndicator(
      //             indicatorRadius: 20.0,
      //             tabBarIndicatorSize: TabBarIndicatorSize.tab,
      //             indicatorHeight: 40.0,
      //             indicatorColor: Colors.white,
      //           ),
      //           labelStyle: Styles.tabTextStyle,
      //           labelColor: Colors.black,
      //           unselectedLabelColor: Colors.white,
      //           tabs: const <Widget>[
      //             Text('LICENSE'),
      //             Text('VEHICLE'),
      //           ],
      //           onTap: (index) {},
      //         ),
      //       ),
      //     ),
      //   );
      // }

      // SliverPadding _buildStatsTabBar() {
      //   return SliverPadding(
      //     padding: const EdgeInsets.all(20.0),
      //     sliver: SliverToBoxAdapter(
      //       child: DefaultTabController(
      //         length: 3,
      //         child: TabBar(
      //           indicatorColor: Colors.transparent,
      //           labelStyle: Styles.tabTextStyle,
      //           labelColor: Colors.black,
      //           unselectedLabelColor: Colors.white60,
      //           tabs: const <Widget>[
      //             Text(
      //               'Total',
      //               style: TextStyle(color: Colors.black),
      //             ),
      //             Text(
      //               'Today',
      //               style: TextStyle(color: Colors.black),
      //             ),
      //             Text(
      //               'Yesterday',
      //               style: TextStyle(color: Colors.black),
      //             ),
      //           ],
      //           onTap: (index) {},
      //         ),
      //       ),
      //     ),
    );
  }
}
