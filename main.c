#include <bpf/libbpf.h>
int main() {
  return bpf_object__open(0) < 0;
}
