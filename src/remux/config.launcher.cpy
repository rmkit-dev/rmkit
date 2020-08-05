struct RMApp:
  string bin
  string name
  string term
  string desc

RMApp APP_XOCHITL      = %{
  .bin = "xochitl",
  .name = "Remarkable",
  .term = "systemctl stop xochitl; killall xochitl;"
}
RMApp APP_HARMONY      = %{
  .bin="/home/root/harmony/harmony.exe",
  .name="Harmony" ,
  .term="killall harmony"}
RMApp APP_KOREADER     = %{
  .bin="/home/root/koreader/koreader.sh",
  .name="KOReader",
  .term="killall koreader"}



vector<RMApp> APPS = %{
   APP_XOCHITL
  // ,APP_HARMONY
  ,APP_KOREADER
}
