import 'package:floors_map_widget/floors_map_widget.dart';
import 'package:flutter/material.dart';

abstract class ExampleBottomSheet {
  static Future<void> showBottomSheet(
    final BuildContext context,
    final FloorItem item,
    final VoidCallback selectStartPoint,
    final VoidCallback selectEndPoint,
  ) async {
    await showModalBottomSheet(
      context: context,
      builder: (final context) => SizedBox(
        width: double.infinity,
        height: 250,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Type item: ${item.runtimeType}'),
              Text('Id item: ${item.key}'),
              Text('Id anchor point: ${item.idPoint}'),
              Text('Floor number: ${item.floor}'),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      selectStartPoint.call();
                      Navigator.pop(context);
                    },
                    child: const Text('Set start point'),
                  ),
                  const SizedBox(width: 18),
                  ElevatedButton(
                    onPressed: () {
                      selectEndPoint.call();
                      Navigator.pop(context);
                    },
                    child: const Text('Set end point'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      elevation: 10,
    );
  }
}
