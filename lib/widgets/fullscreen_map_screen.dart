import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:partener_app/services/routing_service.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:partener_app/models/user_model.dart';
import 'package:get/get.dart';

class FullscreenMapScreen extends StatefulWidget {
  final List<LatLng> routePoints;
  final List<Map<String, dynamic>> visits;
  final String title;
  final String? subtitle;
  final LatLng? initialCenter;

  // Team tracking fields
  final Map<int, LatLng>? employeeLocations;
  final List<UserModel>? employees;
  final bool isTeamMode;

  const FullscreenMapScreen({
    super.key,
    required this.routePoints,
    required this.visits,
    required this.title,
    this.subtitle,
    this.initialCenter,
    this.employeeLocations,
    this.employees,
    this.isTeamMode = false,
  });

  @override
  State<FullscreenMapScreen> createState() => _FullscreenMapScreenState();
}

class _FullscreenMapScreenState extends State<FullscreenMapScreen> {
  final MapController _mapController = MapController();
  String _selectedFilter = 'ALL';
  late bool _teamModeActive;

  // States if we dynamically load an employee route in fullscreen
  List<LatLng> _currentRoutePoints = [];
  List<Map<String, dynamic>> _currentVisits = [];
  String _currentTitle = '';
  String? _currentSubtitle;

  @override
  void initState() {
    super.initState();
    _teamModeActive = widget.isTeamMode;
    _currentRoutePoints = List.from(widget.routePoints);
    _currentVisits = List.from(widget.visits);
    _currentTitle = widget.title;
    _currentSubtitle = widget.subtitle;
  }

  @override
  Widget build(BuildContext context) {
    LatLng mapCenter = const LatLng(20.5937, 78.9629);

    if (_teamModeActive &&
        widget.employeeLocations != null &&
        widget.employeeLocations!.isNotEmpty) {
      mapCenter = widget.employeeLocations!.values.first;
    } else if (_currentRoutePoints.isNotEmpty) {
      mapCenter = _currentRoutePoints.last;
    } else if (widget.initialCenter != null) {
      mapCenter = widget.initialCenter!;
    }

    final filteredVisits =
        _currentVisits.where((v) {
          if (_selectedFilter == 'ALL') return true;
          return v['type'] == _selectedFilter;
        }).toList();

    return Scaffold(
      body: Stack(
        children: [
          // The Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: mapCenter,
              initialZoom:
                  _teamModeActive
                      ? 6.5
                      : (_currentRoutePoints.isNotEmpty ? 14.5 : 6.0),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.yashagro.app',
              ),

              // Draw Route Polyline if not in team mode
              if (!_teamModeActive && _currentRoutePoints.isNotEmpty)
                RoadPolylineLayer(
                  rawPoints: _currentRoutePoints,
                  color: Colors.blue.shade700,
                  strokeWidth: 5.0,
                ),

              MarkerLayer(
                markers: [
                  if (!_teamModeActive) ...[
                    // Route Start Pin
                    if (_currentRoutePoints.isNotEmpty)
                      Marker(
                        point: _currentRoutePoints.first,
                        width: 16,
                        height: 16,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    // Route Last Pin
                    if (_currentRoutePoints.isNotEmpty)
                      Marker(
                        point: _currentRoutePoints.last,
                        width: 24,
                        height: 24,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    // Visit Pins
                    ...filteredVisits.map((v) {
                      final lat = double.tryParse(
                        v['latitude']?.toString() ?? '',
                      );
                      final lon = double.tryParse(
                        v['longitude']?.toString() ?? '',
                      );
                      if (lat == null || lon == null) {
                        return const Marker(
                          point: LatLng(0, 0),
                          child: SizedBox.shrink(),
                        );
                      }
                      final isFarm = v['type'] == 'FARM_VISIT';
                      return Marker(
                        point: LatLng(lat, lon),
                        width: 40,
                        height: 40,
                        child: GestureDetector(
                          onTap: () => _showVisitDetailsBottomSheet(context, v),
                          child: Container(
                            decoration: BoxDecoration(
                              color:
                                  isFarm
                                      ? Colors.green.shade600
                                      : Colors.orange.shade600,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(
                              isFarm
                                  ? Icons.agriculture_rounded
                                  : Icons.storefront_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ] else ...[
                    // Render All Team Members
                    if (widget.employeeLocations != null &&
                        widget.employees != null)
                      ...widget.employeeLocations!.entries.map((entry) {
                        final emp = widget.employees!.firstWhereOrNull(
                          (e) => e.id == entry.key,
                        );
                        if (emp == null)
                          return const Marker(
                            point: LatLng(0, 0),
                            child: SizedBox.shrink(),
                          );
                        final isOnline = emp.status == 'ACTIVE';

                        return Marker(
                          point: entry.value,
                          width: 80,
                          height: 60,
                          child: GestureDetector(
                            onTap:
                                () => _showEmployeeDetailsBottomSheet(
                                  context,
                                  emp,
                                  entry.value,
                                ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color:
                                        isOnline
                                            ? Colors.green.shade600
                                            : Colors.red.shade600,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 6,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    isOnline
                                        ? Icons.directions_walk_rounded
                                        : Icons.location_off_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.95),
                                    borderRadius: BorderRadius.circular(4),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    emp.name ?? '',
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                  ],
                ],
              ),
            ],
          ),

          // Header Card
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.black87,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _teamModeActive
                              ? "Team Live Location Map"
                              : _currentTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          _teamModeActive
                              ? "${widget.employeeLocations?.length ?? 0} active members tracked"
                              : (_currentSubtitle ??
                                  DateFormat(
                                    'EEEE, d MMMM yyyy',
                                  ).format(DateTime.now())),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_teamModeActive)
                    IconButton(
                      icon: const Icon(
                        Icons.navigation_rounded,
                        color: Colors.blue,
                      ),
                      onPressed: () {
                        final pts =
                            _currentRoutePoints.isNotEmpty
                                ? _currentRoutePoints
                                : [mapCenter];
                        RoutingService.launchGoogleMapsRoute(pts);
                      },
                      tooltip: "Open in Google Maps",
                    ),
                  if (widget.isTeamMode && !_teamModeActive)
                    IconButton(
                      icon: const Icon(
                        Icons.group_rounded,
                        color: Colors.purple,
                      ),
                      tooltip: "Show All Team",
                      onPressed: () {
                        setState(() {
                          _teamModeActive = true;
                        });
                      },
                    ),
                ],
              ),
            ),
          ),

          // Controls & Filter panel at bottom (Only shown when viewing a specific route)
          if (!_teamModeActive)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Filter Map Visits",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          "${filteredVisits.length} Marked",
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildFilterBtn("ALL", "All"),
                        const SizedBox(width: 8),
                        _buildFilterBtn("FARM_VISIT", "Farms"),
                        const SizedBox(width: 8),
                        _buildFilterBtn("CUSTOMER_VISIT", "Stores"),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterBtn(String value, String label) {
    final isSelected = _selectedFilter == value;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedFilter = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.shade700 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? Colors.blue.shade700 : Colors.grey.shade200,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  void _showVisitDetailsBottomSheet(
    BuildContext context,
    Map<String, dynamic> visit,
  ) {
    final isFarm = visit['type'] == 'FARM_VISIT';
    final payload = visit['payload'] as Map<String, dynamic>? ?? {};
    final name =
        payload['customer_name']?.toString() ??
        visit['customer_name']?.toString() ??
        payload['name']?.toString() ??
        'Unknown Customer';
    final phone =
        payload['mobile_no']?.toString() ??
        payload['mobile']?.toString() ??
        visit['mobile_no']?.toString() ??
        visit['mobile']?.toString() ??
        'N/A';
    final crop =
        payload['crop_name']?.toString() ?? visit['crop_name']?.toString();
    final timeStr =
        visit['created_at'] != null
            ? DateFormat(
              'hh:mm a',
            ).format(DateTime.parse(visit['created_at']).toLocal())
            : 'N/A';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:
                          isFarm ? Colors.green.shade50 : Colors.orange.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isFarm
                          ? Icons.agriculture_rounded
                          : Icons.storefront_rounded,
                      color:
                          isFarm
                              ? Colors.green.shade700
                              : Colors.orange.shade700,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          isFarm
                              ? "Farm Visit${crop != null ? ' • $crop' : ''}"
                              : "Store/Shop Visit",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    timeStr,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (phone != 'N/A' && phone.isNotEmpty) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.phone_iphone_rounded,
                    color: Colors.blueGrey,
                  ),
                  title: const Text(
                    "Mobile Number",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  subtitle: Text(
                    phone,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.phone_rounded),
                        label: const Text("Call"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => launchUrl(Uri.parse('tel:$phone')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.chat_bubble_rounded),
                        label: const Text("WhatsApp"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed:
                            () => launchUrl(Uri.parse('https://wa.me/$phone')),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(
                    child: Text(
                      "No contact details available for this visit",
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showEmployeeDetailsBottomSheet(
    BuildContext context,
    UserModel emp,
    LatLng location,
  ) {
    final isOnline = emp.status == 'ACTIVE';
    final phone = emp.mobileNo ?? 'N/A';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color:
                          isOnline ? Colors.green.shade50 : Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isOnline
                          ? Icons.directions_walk_rounded
                          : Icons.location_off_rounded,
                      color:
                          isOnline
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          emp.name ?? 'Unknown Employee',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isOnline ? Colors.green : Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isOnline ? "Online" : "Offline",
                              style: TextStyle(
                                color:
                                    isOnline
                                        ? Colors.green.shade700
                                        : Colors.red.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (phone != 'N/A' && phone.isNotEmpty) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.phone_iphone_rounded,
                    color: Colors.blueGrey,
                  ),
                  title: const Text(
                    "Contact Number",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  subtitle: Text(
                    phone,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.phone_rounded),
                        label: const Text("Call"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => launchUrl(Uri.parse('tel:$phone')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.chat_bubble_rounded),
                        label: const Text("WhatsApp"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed:
                            () => launchUrl(Uri.parse('https://wa.me/$phone')),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              ElevatedButton.icon(
                icon: const Icon(Icons.route_rounded),
                label: const Text("View Today's Route History"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  // Load individual route details into fullscreen map
                  try {
                    final todayStr = DateFormat(
                      'yyyy-MM-dd',
                    ).format(DateTime.now());
                    final rangeData =
                        await RoutingService.fetchRouteRangeSummaryDirect(
                          emp.id!,
                          todayStr,
                          todayStr,
                        );
                    if (rangeData != null) {
                      final locations =
                          rangeData['locations'] as List<dynamic>? ?? [];
                      final List<LatLng> pts = [];
                      for (var loc in locations) {
                        final locStr = loc['location'] as String?;
                        if (locStr != null) {
                          final parts = locStr.split(',');
                          if (parts.length == 2) {
                            final lat = double.tryParse(parts[0].trim());
                            final lon = double.tryParse(parts[1].trim());
                            if (lat != null && lon != null) {
                              pts.add(LatLng(lat, lon));
                            }
                          }
                        }
                      }
                      final List<Map<String, dynamic>> vsts = [];
                      final visitsData =
                          rangeData['emp_visits'] as List<dynamic>? ?? [];
                      for (var v in visitsData) {
                        if (v is Map) vsts.add(Map<String, dynamic>.from(v));
                      }

                      setState(() {
                        _teamModeActive = false;
                        _currentRoutePoints = pts;
                        _currentVisits = vsts;
                        _currentTitle = emp.name ?? 'Employee Route';
                        _currentSubtitle = "Live Route • $todayStr";
                      });

                      if (pts.isNotEmpty) {
                        _mapController.move(pts.last, 14.5);
                      }
                    }
                  } catch (e) {
                    Get.snackbar("Error", "Could not load route history.");
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
