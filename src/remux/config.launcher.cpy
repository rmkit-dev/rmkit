struct RMApp:
  string bin
  string name
  string term
  string desc
  bool always_show = false

RMApp APP_XOCHITL      = %{
  .bin = "xochitl",
  .name = "Remarkable",
  .term = "systemctl stop xochitl; killall xochitl;",
  .always_show = true
}

RMApp APP_HARMONY      = %{
  .bin="/home/root/harmony/harmony.exe",
  .name="Harmony" ,
  .term="killall harmony"}

RMApp APP_KOREADER     = %{
  .bin="/home/root/koreader/koreader.sh",
  .name="KOReader",
  .term="killall koreader"}

RMApp APP_FINGERTERM     = %{
  .bin="/home/root/apps/fingerterm",
  .name="FingerTerm",
  .term="killall fingerterm",
  }

RMApp APP_KEYWRITER     = %{
  .bin="/home/root/apps/keywriter",
  .name="KeyWriter",
  .term="killall keywriter",
}

RMApp APP_EDIT     = %{
  .bin="/home/root/apps/edit",
  .name="Edit",
  .term="killall edit",
}



vector<RMApp> APPS = %{
   APP_XOCHITL
  // ,APP_HARMONY
  ,APP_KOREADER
  ,APP_FINGERTERM
  ,APP_KEYWRITER
  ,APP_EDIT
}
