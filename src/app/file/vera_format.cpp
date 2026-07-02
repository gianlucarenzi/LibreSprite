// LibreSprite | Copyright (C) 2026       LibreSprite contributors
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License version 2 as
// published by the Free Software Foundation.
//
// Exports 8bpp indexed sprites for the Commander X16's VERA video chip.
//
// File layout (all values little-endian, palette inline):
//   offset 0:   4 bytes  magic "VSP1"
//   offset 4:   1 byte   sprite width in pixels  (8/16/32/64)
//   offset 5:   1 byte   sprite height in pixels (8/16/32/64)
//   offset 6:   1 byte   bits per pixel (always 8)
//   offset 7:   1 byte   reserved (0)
//   offset 8:   512 bytes  palette, 256 entries x 2 bytes, VERA 12-bit
//                          RGB444 format (byte0 = GGGGBBBB, byte1 = 0000RRRR)
//   offset 520: width*height bytes  pixel data, 1 byte per pixel (palette
//                          index), row-major, top-left to bottom-right
//
// See "VERA Programmer's Reference" (Palette / Sprite attributes) for the
// hardware format this mirrors.

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include "app/file/file.h"
#include "app/file/file_format.h"
#include "app/file/format_options.h"
#include "base/file_handle.h"
#include "doc/doc.h"

namespace app {

using namespace base;

class VeraFormat : public FileFormat {
  const char* onGetName() const override { return "vera"; }
  const char* onGetExtensions() const override { return "vera"; }
  int onGetFlags() const override {
    return
      FILE_SUPPORT_SAVE |
      FILE_SUPPORT_INDEXED |
      FILE_SUPPORT_SEQUENCES;
  }

  bool onLoad(FileOp* fop) override { return false; }
  bool onSave(FileOp* fop) override;
};

static FileFormat::Regular<VeraFormat> ff{"vera"};

static bool is_valid_sprite_dimension(int px) {
  return px == 8 || px == 16 || px == 32 || px == 64;
}

bool VeraFormat::onSave(FileOp* fop)
{
  const Image* image = fop->sequenceImage();

  if (!image || image->pixelFormat() != IMAGE_INDEXED) {
    fop->setError("The VERA sprite format only supports indexed-color images.\n");
    return false;
  }

  if (!is_valid_sprite_dimension(image->width()) ||
      !is_valid_sprite_dimension(image->height())) {
    fop->setError("VERA sprites must be 8, 16, 32, or 64 pixels wide and tall "
                   "(got %dx%d).\n", image->width(), image->height());
    return false;
  }

  FileHandle handle(open_file_with_exception(fop->filename(), "wb"));
  FILE* f = handle.get();

  fputc('V', f);
  fputc('S', f);
  fputc('P', f);
  fputc('1', f);
  fputc(image->width(), f);
  fputc(image->height(), f);
  fputc(8, f);  // bits per pixel
  fputc(0, f);  // reserved

  // Palette: always the full 256 VERA slots, ready to be copied straight
  // into VRAM palette RAM.
  for (int i = 0; i < 256; i++) {
    int r, g, b;
    fop->sequenceGetColor(i, &r, &g, &b);
    int r4 = (r >> 4) & 0x0f;
    int g4 = (g >> 4) & 0x0f;
    int b4 = (b >> 4) & 0x0f;
    fputc((g4 << 4) | b4, f);
    fputc(r4, f);
  }

  // Pixel data: one byte per pixel (palette index), row-major.
  for (int y = 0; y < image->height(); y++) {
    for (int x = 0; x < image->width(); x++) {
      fputc(get_pixel_fast<IndexedTraits>(image, x, y), f);
    }
    fop->setProgress((float)(y + 1) / (float)image->height());
  }

  if (ferror(f)) {
    fop->setError("Error writing file.\n");
    return false;
  }
  return true;
}

} // namespace app
