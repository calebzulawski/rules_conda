#include <png.h>

#include <cstdlib>
#include <cstdio>
#include <cstring>
#include <string>

int main() {
  const char *tmpdir = std::getenv("TEST_TMPDIR");
  std::string path = tmpdir ? std::string(tmpdir) + "/png_test.png" : "png_test.png";
  FILE *fp = std::fopen(path.c_str(), "wb");
  if (!fp) {
    std::perror("fopen");
    return 1;
  }

  png_structp png_ptr = png_create_write_struct(PNG_LIBPNG_VER_STRING, nullptr, nullptr, nullptr);
  if (!png_ptr) {
    std::fclose(fp);
    return 1;
  }
  png_infop info_ptr = png_create_info_struct(png_ptr);
  if (!info_ptr) {
    png_destroy_write_struct(&png_ptr, nullptr);
    std::fclose(fp);
    return 1;
  }
  if (setjmp(png_jmpbuf(png_ptr))) {
    png_destroy_write_struct(&png_ptr, &info_ptr);
    std::fclose(fp);
    return 1;
  }

  png_init_io(png_ptr, fp);
  png_set_IHDR(
      png_ptr,
      info_ptr,
      1,
      1,
      8,
      PNG_COLOR_TYPE_GRAY,
      PNG_INTERLACE_NONE,
      PNG_COMPRESSION_TYPE_BASE,
      PNG_FILTER_TYPE_BASE);
  png_write_info(png_ptr, info_ptr);

  png_byte pixel = 0x7f;
  png_bytep row = &pixel;
  png_write_row(png_ptr, row);
  png_write_end(png_ptr, nullptr);

  png_destroy_write_struct(&png_ptr, &info_ptr);
  std::fclose(fp);
  std::remove(path.c_str());
  return 0;
}
