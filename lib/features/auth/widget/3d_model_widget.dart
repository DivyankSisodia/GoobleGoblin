import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class Rotating3DModel extends StatelessWidget {
  const Rotating3DModel({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: ModelViewer(
        src: 'assets/3d_model/dollar_sign.glb',
        alt: '3D Dollar Sign',
        autoRotate: true,
        rotationPerSecond: '30deg',
        cameraControls: true,
        // disableZoom: true,
        // disablePan: true,
        backgroundColor: Colors.transparent,
        autoPlay: true,
        loading: Loading.eager,
        interactionPrompt: InteractionPrompt.none,
      ),
    );
  }
}
