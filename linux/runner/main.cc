#include "my_application.h"

#if defined(__linux__) || __has_include(<gtk/gtk.h>)
int main(int argc, char** argv) {
  g_autoptr(MyApplication) app = my_application_new();
  return g_application_run(G_APPLICATION(app), argc, argv);
}
#else
int main(int argc, char** argv) {
  (void)argc;
  (void)argv;
  return 0;
}
#endif
