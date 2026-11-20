import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:partener_app/models/user_model.dart';
import 'package:partener_app/super_manager/controller/super_manager_employee_list_controller.dart';
import 'package:partener_app/managers/view/manager_employee_details_screen.dart';

class SuperManagerEmployeeListScreen extends StatelessWidget {
  final UserModel manager;

  const SuperManagerEmployeeListScreen({super.key, required this.manager});

  @override
  Widget build(BuildContext context) {
    // We use Get.put with a tag to handle multiple instances if navigating quickly
    final controller = Get.put(
      SuperManagerEmployeeListController(managerId: manager.id ?? 0),
      tag: manager.id.toString(),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F9F9),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Get.back(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Team under',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              manager.name ?? 'Manager',
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(Icons.work_history_rounded, color: Colors.purple.shade700),
              tooltip: "View Manager's Work Details",
              onPressed: () {
                Get.to(() => ManagerEmployeeDetailsScreen(employee: manager));
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(Icons.refresh, color: Colors.purple.shade700),
              onPressed: () => controller.fetchEmployees(),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value && controller.employees.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.errorMessage.value.isNotEmpty &&
              controller.employees.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      controller.errorMessage.value,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: controller.fetchEmployees,
            color: Colors.purple.shade700,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                _ManagerHeaderCard(manager: manager),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Text(
                      "Assigned Team",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "${controller.employees.length}",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (controller.employees.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.group_off,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No employees assigned to this manager yet.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...controller.employees
                      .map((employee) => _EmployeeCard(
                            employee: employee,
                            managerId: manager.id ?? 0,
                          ))
                      .toList(),
              ],
            ),
          );
        }),
      ),
    );
  }
}


class _EmployeeCard extends StatelessWidget {
  final UserModel employee;
  final int managerId;

  const _EmployeeCard({required this.employee, required this.managerId});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // Navigate to employee details screen using the existing one
            Get.to(() => ManagerEmployeeDetailsScreen(employee: employee));
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Hero(
                  tag: 'super_emp_${employee.id}',
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.15),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.blue.shade50,
                      backgroundImage:
                          (employee.image != null && employee.image!.isNotEmpty)
                              ? NetworkImage(employee.image!)
                              : null,
                      child:
                          (employee.image == null || employee.image!.isEmpty)
                              ? Icon(
                                  Icons.person,
                                  size: 28,
                                  color: Colors.blue.shade400,
                                )
                              : null,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee.name ?? "Unknown",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.badge_outlined,
                            size: 13,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "ID: ${employee.id ?? 'N/A'}",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.phone_outlined,
                            size: 13,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            employee.mobileNo ?? "No Phone",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ManagerHeaderCard extends StatelessWidget {
  final UserModel manager;

  const _ManagerHeaderCard({required this.manager});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.shade700,
            Colors.purple.shade900,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.shade900.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            Get.to(() => ManagerEmployeeDetailsScreen(employee: manager));
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.white24,
                        backgroundImage:
                            (manager.image != null && manager.image!.isNotEmpty)
                                ? NetworkImage(manager.image!)
                                : null,
                        child: (manager.image == null || manager.image!.isEmpty)
                            ? const Icon(Icons.person,
                                size: 28, color: Colors.white)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  manager.name ?? "Manager",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  "Manager",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "ID: ${manager.id ?? 'N/A'}${manager.mobileNo != null ? ' • ${manager.mobileNo}' : ''}",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.route_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          "View Manager Work & Route Details",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_rounded,
                          color: Colors.white70, size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

