struct RMApp:
  string bin
  string which = "XBXA"

  string name = "" // from draft launcher
  string term = "" // from draft launcher
  string desc = "" // from draft launcher
  string resume = ""

  bool always_show = false
  bool manage_power = true
  int bpp = 16

  // this will contain a framebuffer snapshot if we have one
  char *snapshot = NULL

  // proc management stuff below here
  // whether this app is currently running
  bool is_running = false
  int mem_usage = 0 // in KB
  vector<int> pids


RMApp APP_XOCHITL = RMApp %{
  bin : "xochitl",
  which : "xochitl",
  name : "Remarkable",
  always_show : true,
  manage_power : false,
  bpp: 16
}

RMApp APP_NICKEL = RMApp %{
  bin : "nickel",
  which : "nickel",
  name : "Nickel",
  always_show : true,
  manage_power : false,
  bpp: 32
}

RMApp APP_NONE = RMApp %{
  bin : "/usr/bin/false",
  which : "false",
  name : "",
  always_show : false,
  manage_power : false,
}

#ifdef REMARKABLE
RMApp APP_MAIN = APP_XOCHITL
#elif KOBO
RMApp APP_MAIN = APP_NICKEL
#else
RMApp APP_MAIN = APP_NONE
#endif


RMApp APP_KOREADER = RMApp %{
  bin:"/home/root/koreader/koreader.sh",
  which:"koreader.sh",
  name:"KOReader",
}

RMApp APP_FINGERTERM = RMApp %{
  bin:"/home/root/apps/fingerterm",
  which:"fingerterm",
  name:"FingerTerm",
}

RMApp APP_KEYWRITER = RMApp %{
  bin:"/home/root/apps/keywriter",
  which:"keywriter",
  name:"KeyWriter",
}

RMApp APP_EDIT = RMApp %{
  bin:"/home/root/apps/edit",
  which:"edit",
  name:"Edit",
}



vector<RMApp> APPS = %{
   APP_MAIN
  ,APP_KOREADER
  ,APP_FINGERTERM
  ,APP_KEYWRITER
  ,APP_EDIT
}
