#ifndef PROCESSING_H_
#define PROCESSING_H_

/// Get the current uptime, all formatted.
void get_uptime(char *uptime_buffer);
void get_nvidia(char *nvidia_buffer);
void get_disk_space(char *disks_buffer);
void get_kernel(char *kernel_buffer);
void get_term(char *term_buffer);

/// Get the XDG_CURRENT_DESKTOP environment variable, populating the name
/// buffer. Returns a pointer to the const string that contains the icon.
const char *get_desktop(char *name_buffer);

#endif
