// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_SURFACE_METAL_IMPELLER_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_SURFACE_METAL_IMPELLER_H_

#include "flutter/fml/macros.h"
#include "flutter/shell/gpu/gpu_surface_metal_delegate.h"
#import "flutter/shell/platform/darwin/ios/ios_surface.h"

@class CAMetalLayer;

namespace flutter {

class SK_API_AVAILABLE_CA_METAL_LAYER IOSSurfaceMetalImpeller final
    : public IOSSurface,
      public GPUSurfaceMetalDelegate {
 public:
  IOSSurfaceMetalImpeller(fml::scoped_nsobject<CAMetalLayer> layer,
                          std::shared_ptr<IOSContext> context);

  // |IOSSurface|
  ~IOSSurfaceMetalImpeller();

 private:
  fml::scoped_nsobject<CAMetalLayer> layer_;
  bool is_valid_ = false;

  // |IOSSurface|
  bool IsValid() const override;

  // |IOSSurface|
  void UpdateStorageSizeIfNecessary() override;

  // |IOSSurface|
  std::unique_ptr<Surface> CreateGPUSurface(GrDirectContext* gr_context) override;

  // |GPUSurfaceMetalDelegate|
  GPUCAMetalLayerHandle GetCAMetalLayer(const SkISize& frame_info) const override;

  // |GPUSurfaceMetalDelegate|
  bool PresentDrawable(GrMTLHandle drawable) const override;

  // |GPUSurfaceMetalDelegate|
  GPUMTLTextureInfo GetMTLTexture(const SkISize& frame_info) const override;

  // |GPUSurfaceMetalDelegate|
  bool PresentTexture(GPUMTLTextureInfo texture) const override;

  // |GPUSurfaceMetalDelegate|
  bool AllowsDrawingWhenGpuDisabled() const override;

  FML_DISALLOW_COPY_AND_ASSIGN(IOSSurfaceMetalImpeller);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_SURFACE_METAL_IMPELLER_H_
