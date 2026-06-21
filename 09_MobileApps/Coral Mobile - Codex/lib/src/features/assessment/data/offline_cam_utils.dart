import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:convert';
import 'package:image/image.dart' as img;

class OfflineCamUtils {
  /// Compute an activation-based CAM from the top_conv feature maps
  /// [activations] is expected to be [1, height, width, channels] e.g. [1, 7, 7, 1280]
  static Float32List computeCAM(Float32List activations, int height, int width, int channels) {
    // 1. Compute Global Average Pooling weights
    final weights = Float32List(channels);
    final pixelsPerChannel = height * width;
    
    for (int c = 0; c < channels; c++) {
      double sum = 0;
      for (int i = 0; i < pixelsPerChannel; i++) {
        sum += activations[i * channels + c];
      }
      weights[c] = sum / pixelsPerChannel;
    }
    
    // 2. Compute weighted sum
    final heatmap = Float32List(pixelsPerChannel);
    for (int i = 0; i < pixelsPerChannel; i++) {
      double val = 0;
      for (int c = 0; c < channels; c++) {
        val += weights[c] * activations[i * channels + c];
      }
      // Apply ReLU
      heatmap[i] = math.max(0.0, val);
    }
    
    // 3. Normalize to [0, 1]
    double maxVal = 0;
    for (int i = 0; i < pixelsPerChannel; i++) {
      if (heatmap[i] > maxVal) maxVal = heatmap[i];
    }
    
    if (maxVal > 0) {
      for (int i = 0; i < pixelsPerChannel; i++) {
        heatmap[i] /= maxVal;
      }
    }
    
    return heatmap;
  }

  /// Create a jet colormap from a [0, 1] normalized value
  static List<int> _jetColor(double v) {
    double r = math.max(0.0, math.min(1.0, 1.5 - (v - 0.75).abs() * 4.0));
    double g = math.max(0.0, math.min(1.0, 1.5 - (v - 0.50).abs() * 4.0));
    double b = math.max(0.0, math.min(1.0, 1.5 - (v - 0.25).abs() * 4.0));
    return [(r * 255).toInt(), (g * 255).toInt(), (b * 255).toInt()];
  }

  /// Convert a 7x7 heatmap to a 224x224 RGB image with Jet colormap
  static img.Image createJetHeatmap(Float32List heatmap, int srcSize, int dstSize) {
    // First map to an image of size srcSize x srcSize
    final srcImg = img.Image(width: srcSize, height: srcSize);
    for (int y = 0; y < srcSize; y++) {
      for (int x = 0; x < srcSize; x++) {
        final val = heatmap[y * srcSize + x];
        final color = _jetColor(val);
        // Ensure format is compatible
        srcImg.setPixelRgba(x, y, color[0], color[1], color[2], 255);
      }
    }
    
    // Resize to dstSize
    return img.copyResize(srcImg, width: dstSize, height: dstSize, interpolation: img.Interpolation.linear);
  }

  /// Overlay the heatmap onto the original image
  static img.Image createOverlay(img.Image original, img.Image heatmapImg, {double alpha = 0.4}) {
    // Ensure both are same size
    final resizedHeatmap = img.copyResize(heatmapImg, width: original.width, height: original.height);
    
    final result = img.Image.from(original);
    for (int y = 0; y < result.height; y++) {
      for (int x = 0; x < result.width; x++) {
        final pOrig = original.getPixel(x, y);
        final pHeat = resizedHeatmap.getPixel(x, y);
        
        // Skip background/low intensity pixels of heatmap
        // Calculate intensity based on the jet colormap roughly (b>g>r means low intensity)
        // Alternatively, use alpha blending directly
        int r1 = pOrig.r.toInt();
        int g1 = pOrig.g.toInt();
        int b1 = pOrig.b.toInt();
        
        int r2 = pHeat.r.toInt();
        int g2 = pHeat.g.toInt();
        int b2 = pHeat.b.toInt();
        
        // Simple alpha blending
        int r = (r1 * (1.0 - alpha) + r2 * alpha).toInt();
        int g = (g1 * (1.0 - alpha) + g2 * alpha).toInt();
        int b = (b1 * (1.0 - alpha) + b2 * alpha).toInt();
        
        result.setPixelRgba(x, y, r.clamp(0, 255), g.clamp(0, 255), b.clamp(0, 255), 255);
      }
    }
    
    return result;
  }
  
  /// Encode an image.Image to base64 PNG
  static String encodeToBase64Png(img.Image image) {
    final png = img.encodePng(image);
    return base64Encode(png);
  }
}
