final samples = const <String>[
  "assets/angel.svga",
  "assets/pin_jump.svga",
  "https://cdn.jsdelivr.net/gh/svga/SVGA-Samples@master/EmptyState.svga",
  "https://cdn.jsdelivr.net/gh/svga/SVGA-Samples@master/HamburgerArrow.svga",
  "https://cdn.jsdelivr.net/gh/svga/SVGA-Samples@master/PinJump.svga",
  "https://cdn.jsdelivr.net/gh/svga/SVGA-Samples@master/TwitterHeart.svga",
  "https://cdn.jsdelivr.net/gh/svga/SVGA-Samples@master/Walkthrough.svga",
  "https://cdn.jsdelivr.net/gh/svga/SVGA-Samples@master/kingset.svga",
  "https://cdn.jsdelivr.net/gh/svga/SVGA-Samples@master/halloween.svga",
  "https://cdn.jsdelivr.net/gh/svga/SVGA-Samples@master/heartbeat.svga",
  "https://cdn.jsdelivr.net/gh/svga/SVGA-Samples@master/matteBitmap.svga",
  "https://cdn.jsdelivr.net/gh/svga/SVGA-Samples@master/matteBitmap_1.x.svga",
  "https://cdn.jsdelivr.net/gh/svga/SVGA-Samples@master/matteRect.svga",
  "https://cdn.jsdelivr.net/gh/svga/SVGA-Samples@master/mutiMatte.svga",
  "https://cdn.jsdelivr.net/gh/svga/SVGA-Samples@master/posche.svga",
  "https://cdn.jsdelivr.net/gh/svga/SVGA-Samples@master/rose.svga",
]
    .map(
      (e) => [
        e.split('/').last,
        e,
      ],
    )
    .toList(
      growable: false,
    );
