#include <iostream>
#include <string>
#include <zlib.h>

int main() {
  std::cout << "zlib version: " << zlibVersion() << std::endl;

  // Simple compression test
  std::string input = "Hello, conda + bazel!";
  auto compressed_size = compressBound(input.size());
  std::string compressed(' ', compressed_size);

  int result = compress((Bytef *)compressed.data(), &compressed_size,
                        (Bytef *)input.data(), input.size());

  if (result != Z_OK) {
    std::cerr << "compression failed" << std::endl;
    return 1;
  }

  std::cout << "Original size: " << input.size()
            << ", compressed: " << compressed_size << std::endl;

  return 0;
}
