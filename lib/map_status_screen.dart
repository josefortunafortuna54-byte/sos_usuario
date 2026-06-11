import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class MapStatusScreen extends StatefulWidget {
  final String occurrenceId;

  const MapStatusScreen({super.key, required this.occurrenceId});

  @override
  State<MapStatusScreen> createState() => _MapStatusScreenState();
}

class _MapStatusScreenState extends State<MapStatusScreen> {

  LatLng? currentPosition;
  LatLng? occurrencePosition;
  LatLng? targetPosition;

  Timer? timer;
  Timer? animationTimer;

  @override
  void initState() {
    super.initState();

    fetchStatus();

    timer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => fetchStatus(),

   if (data["occurrenceLocation"] != null) {
  occurrencePosition = LatLng(
    data["occurrenceLocation"]["lat"],
    data["occurrenceLocation"]["lng"],

    );
  }

  // 🚓 movimento suave
  void smoothMove(LatLng newPos) {

    if (currentPosition == null) {
      setState(() {
        currentPosition = newPos;
      });
      return;
    }

    targetPosition = newPos;

    animationTimer?.cancel();

    animationTimer = Timer.periodic(
      const Duration(milliseconds: 50),
      (timer) {

        if (currentPosition == null ||
            targetPosition == null) return;

        final latDiff =
            targetPosition!.latitude -
            currentPosition!.latitude;

        final lngDiff =
            targetPosition!.longitude -
            currentPosition!.longitude;

        if (latDiff.abs() < 0.00001 &&
            lngDiff.abs() < 0.00001) {
          timer.cancel();
          return;
        }

        setState(() {
          currentPosition = LatLng(
            currentPosition!.latitude + latDiff * 0.1,
            currentPosition!.longitude + lngDiff * 0.1,
          );
        });
      },
    );
  }

  Future<void> fetchStatus() async {

    final res = await http.get(
      Uri.parse(
        ""https://sos-server.onrender.com/api/occurrences/${widget.occurrenceId}/status",
      ),
    );

    if (res.statusCode == 200) {

      final data = json.decode(res.body);

      if (data["agent"] != null) {

        final newPos = LatLng(
          data["agent"]["location"]["lat"],
          data["agent"]["location"]["lng"],
        );

        smoothMove(newPos);
      }
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    animationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("🚓 Viatura a Caminho"),
        backgroundColor: Colors.black,
      ),

      body: currentPosition == null
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : FlutterMap(
              options: MapOptions(
                initialCenter: currentPosition!,
                initialZoom: 15,
              ),
              children: [

                TileLayer(
                  urlTemplate:
                  "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                ),

if (occurrencePosition != null)
  PolylineLayer(
    polylines: [
      Polyline(
        points: [
          currentPosition!,
          occurrencePosition!,
        ],
        color: Colors.blue,
        strokeWidth: 4,
      ),
    ],
  ),

if (occurrencePosition != null)
  Marker(
    point: occurrencePosition!,
    width: 60,
    height: 60,
    child: const Icon(
      Icons.location_pin,
      size: 40,
      color: Colors.red,
    ),
  ),



                MarkerLayer(
                  markers: [
                    Marker(
                      point: currentPosition!,
                      width: 60,
                      height: 60,
                      child: const Icon(
                        Icons.local_police,
                        size: 40,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

