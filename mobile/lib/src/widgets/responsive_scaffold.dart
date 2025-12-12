import 'package:flutter/material.dart';
import 'responsive_container.dart';

/// Responsive Scaffold that adapts to different screen sizes
class ResponsiveScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final Widget? bottomSheet;
  final Color? backgroundColor;
  final bool? resizeToAvoidBottomInset;
  final bool extendBody;

  const ResponsiveScaffold({
    super.key,
    this.appBar,
    this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.bottomSheet,
    this.backgroundColor,
    this.resizeToAvoidBottomInset,
    this.extendBody = false,
  });

  @override
  Widget build(BuildContext context) {
    final device = DeviceInfo.of(context);

    return Scaffold(
      appBar: appBar != null ? _buildResponsiveAppBar(context, appBar!) : null,
      body: body != null ? _buildResponsiveBody(context, body!) : null,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
      bottomSheet: bottomSheet,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset ?? true,
      extendBody: extendBody,
    );
  }

  PreferredSizeWidget _buildResponsiveAppBar(BuildContext context, PreferredSizeWidget appBar) {
    if (appBar is AppBar) {
      final device = DeviceInfo.of(context);
      final height = ResponsiveLayout.getAppBarHeight(context);

      return AppBar(
        key: appBar.key,
        leading: appBar.leading,
        automaticallyImplyLeading: appBar.automaticallyImplyLeading,
        title: appBar.title != null ? _buildResponsiveTitle(context, appBar.title!) : null,
        actions: appBar.actions,
        flexibleSpace: appBar.flexibleSpace,
        bottom: appBar.bottom,
        elevation: appBar.elevation,
        shadowColor: appBar.shadowColor,
        shape: appBar.shape,
        backgroundColor: appBar.backgroundColor,
        foregroundColor: appBar.foregroundColor,
        iconTheme: appBar.iconTheme,
        actionsIconTheme: appBar.actionsIconTheme,
        primary: appBar.primary,
        centerTitle: appBar.centerTitle,
        excludeHeaderSemantics: appBar.excludeHeaderSemantics,
        titleSpacing: device.isSmallScreen ? 8 : appBar.titleSpacing,
        toolbarOpacity: appBar.toolbarOpacity,
        bottomOpacity: appBar.bottomOpacity,
        toolbarHeight: height - (appBar.bottom?.preferredSize.height ?? 0),
        leadingWidth: device.isSmallScreen ? 48 : appBar.leadingWidth,
        toolbarTextStyle: appBar.toolbarTextStyle,
        titleTextStyle: appBar.titleTextStyle,
        systemOverlayStyle: appBar.systemOverlayStyle,
      );
    }
    return appBar;
  }

  Widget _buildResponsiveTitle(BuildContext context, Widget title) {
    if (title is Text) {
      final device = DeviceInfo.of(context);
      final fontSize = ResponsiveSize.responsiveFontSize(
        context,
        Theme.of(context).textTheme.titleLarge?.fontSize ?? 20,
      );

      return Text(
        title.data ?? '',
        key: title.key,
        style: title.style?.copyWith(
          fontSize: fontSize,
          fontWeight: device.isSmallScreen ? FontWeight.w600 : title.style?.fontWeight,
        ) ?? TextStyle(fontSize: fontSize),
        strutStyle: title.strutStyle,
        textAlign: title.textAlign,
        textDirection: title.textDirection,
        locale: title.locale,
        softWrap: title.softWrap,
        overflow: device.isSmallScreen ? TextOverflow.ellipsis : title.overflow,
        textScaler: title.textScaler,
        maxLines: device.isSmallScreen ? 1 : title.maxLines,
        semanticsLabel: title.semanticsLabel,
        textWidthBasis: title.textWidthBasis,
        textHeightBehavior: title.textHeightBehavior,
        selectionColor: title.selectionColor,
      );
    }
    return title;
  }

  Widget _buildResponsiveBody(BuildContext context, Widget body) {
    return ResponsiveContainer(
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: body,
      ),
    );
  }
}

/// Responsive ListView that adapts to screen size
class ResponsiveListView extends StatelessWidget {
  final List<Widget> children;
  final Axis scrollDirection;
  final bool reverse;
  final ScrollController? controller;
  final bool? primary;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final EdgeInsetsGeometry? padding;
  final bool addAutomaticKeepAlives;
  final bool addRepaintBoundaries;
  final bool addSemanticIndexes;
  final double? itemExtent;
  final Widget? prototypeItem;
  final int? semanticChildCount;
  final EdgeInsetsGeometry? itemPadding;

  const ResponsiveListView({
    super.key,
    required this.children,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.controller,
    this.primary,
    this.physics,
    this.shrinkWrap = false,
    this.padding,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
    this.itemExtent,
    this.prototypeItem,
    this.semanticChildCount,
    this.itemPadding,
  });

  @override
  Widget build(BuildContext context) {
    final device = DeviceInfo.of(context);

    return ListView(
      scrollDirection: scrollDirection,
      reverse: reverse,
      controller: controller,
      primary: primary,
      physics: physics ?? const BouncingScrollPhysics(),
      shrinkWrap: shrinkWrap,
      padding: padding ?? _getResponsivePadding(device),
      itemExtent: itemExtent,
      prototypeItem: prototypeItem,
      addAutomaticKeepAlives: addAutomaticKeepAlives,
      addRepaintBoundaries: addRepaintBoundaries,
      addSemanticIndexes: addSemanticIndexes,
      semanticChildCount: semanticChildCount,
      children: children.map((child) => _wrapChildWithPadding(context, child)).toList(),
    );
  }

  EdgeInsets _getResponsivePadding(DeviceInfo device) {
    if (padding != null) return padding as EdgeInsets;

    switch (device.type) {
      case DeviceType.smallPhone:
        return const EdgeInsets.all(8);
      case DeviceType.normalPhone:
        return const EdgeInsets.all(12);
      case DeviceType.largePhone:
        return const EdgeInsets.all(16);
      case DeviceType.tablet:
        return const EdgeInsets.all(20);
      case DeviceType.largeTablet:
        return const EdgeInsets.all(24);
    }
  }

  Widget _wrapChildWithPadding(BuildContext context, Widget child) {
    if (itemPadding == null) return child;

    return Padding(
      padding: itemPadding!,
      child: child,
    );
  }
}

/// Responsive GridView for different screen sizes
class ResponsiveGridView extends StatelessWidget {
  final List<Widget> children;
  final double? mainAxisSpacing;
  final double? crossAxisSpacing;
  final double? childAspectRatio;
  final EdgeInsetsGeometry? padding;

  const ResponsiveGridView({
    super.key,
    required this.children,
    this.mainAxisSpacing,
    this.crossAxisSpacing,
    this.childAspectRatio,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final device = DeviceInfo.of(context);
    final crossAxisCount = ResponsiveLayout.getGridCrossAxisCount(context);
    final mainAxisExtent = ResponsiveLayout.getGridMainAxisExtent(context);

    return GridView.count(
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: mainAxisSpacing ?? (device.isSmallScreen ? 8 : 12),
      crossAxisSpacing: crossAxisSpacing ?? (device.isSmallScreen ? 8 : 12),
      childAspectRatio: childAspectRatio ?? 1.0,
      padding: padding ?? _getResponsivePadding(device),
      physics: const BouncingScrollPhysics(),
      children: children,
    );
  }

  EdgeInsets _getResponsivePadding(DeviceInfo device) {
    switch (device.type) {
      case DeviceType.smallPhone:
        return const EdgeInsets.all(8);
      case DeviceType.normalPhone:
        return const EdgeInsets.all(12);
      case DeviceType.largePhone:
        return const EdgeInsets.all(16);
      case DeviceType.tablet:
        return const EdgeInsets.all(20);
      case DeviceType.largeTablet:
        return const EdgeInsets.all(24);
    }
  }
}
