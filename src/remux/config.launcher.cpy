struct RMApp:
  string bin
  string which = "XBXA"

  string name = "" // from draft launcher
  string term = "" // from draft launcher
  string desc = "" // from draft launcher
  string resume = ""

  bool always_show = false
  bool manage_power = true

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
}

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
   APP_XOCHITL
  ,APP_KOREADER
  ,APP_FINGERTERM
  ,APP_KEYWRITER
  ,APP_EDIT
}
