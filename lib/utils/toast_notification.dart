import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

class AppToasts{
  static void showSuccessToast(BuildContext context){
    toastification.show(
        context: context, // optional if you use ToastificationWrapper
        type: ToastificationType.success,
        style: ToastificationStyle.simple,
        autoCloseDuration: const Duration(seconds: 3),
        title: Text('Successfully Authenticated'),
        // you can also use RichText widget for title and description parameters
        // description: RichText(text: const TextSpan(text: 'This is a sample toast message. ')),
        alignment: Alignment.bottomCenter,
        // direction: TextDirection.ltr,
        animationDuration: const Duration(milliseconds: 300),
        animationBuilder: (context, animation, alignment, child) {
          return FadeTransition(
            // turns: animation,
            opacity: animation,
            child: child,
          );
        },
        icon: Image.asset('assets/app_icon/app_icon_dark_mode.png', width: 50, height: 50, ),
        showIcon: true, // show or hide the icon
        primaryColor: Colors.green,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 8),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x07000000), blurRadius: 16, offset: Offset(0, 16), spreadRadius: 0)],
        showProgressBar: true,
        // closeButton: ToastCloseButton(
        //   showType: CloseButtonShowType.onHover,
        //   buttonBuilder: (context, onClose) {
        //     return OutlinedButton.icon(onPressed: onClose, icon: const Icon(Icons.close, size: 20), label: const Text('Close'));
        //   },
        // ),
        // closeOnClick: false,
        // pauseOnHover: true,
        // dragToClose: true,
        // applyBlurEffect: true,
        // callbacks: ToastificationCallbacks(onTap: (toastItem) => print('Toast ${toastItem.id} tapped'), onCloseButtonTap: (toastItem) => print('Toast ${toastItem.id} close button tapped'), onAutoCompleteCompleted: (toastItem) => print('Toast ${toastItem.id} auto complete completed'), onDismissed: (toastItem) => print('Toast ${toastItem.id} dismissed')),
      );
  }
}