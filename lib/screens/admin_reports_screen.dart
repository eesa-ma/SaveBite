import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:save_bite/models/report.dart';
import 'package:save_bite/services/report_service.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  static const Color _primaryColor = Color(0xFF2E7D32);

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  final ReportService _reportService = ReportService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _filterStatus = 'all'; // all, pending, reviewed, resolved

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Safety Reports'),
        backgroundColor: AdminReportsScreen._primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey[100],
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterButton('All', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterButton('Pending', 'pending'),
                  const SizedBox(width: 8),
                  _buildFilterButton('Reviewed', 'reviewed'),
                  const SizedBox(width: 8),
                  _buildFilterButton('Resolved', 'resolved'),
                ],
              ),
            ),
          ),
          // Reports List
          Expanded(child: _buildReportsList()),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, String status) {
    final isSelected = _filterStatus == status;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _filterStatus = status);
      },
      selectedColor: AdminReportsScreen._primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected
            ? AdminReportsScreen._primaryColor
            : Colors.grey[300]!,
      ),
    );
  }

  Widget _buildReportsList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _filterStatus == 'all'
          ? _reportService.streamAllReports()
          : _reportService.streamReportsByStatus(_filterStatus),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: AdminReportsScreen._primaryColor,
            ),
          );
        }

        final reports = snapshot.data?.docs ?? [];

        if (reports.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No reports',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final reportDoc = reports[index];
            final report = Report.fromDoc(reportDoc);

            return _buildReportCard(report, reportDoc.id);
          },
        );
      },
    );
  }

  Widget _buildReportCard(Report report, String reportId) {
    final statusColor = _getStatusColor(report.status);
    final statusLabel = report.status.toUpperCase();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        onTap: () => _showReportDetails(report, reportId),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.foodName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          report.restaurantName,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Reason and Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reason',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          report.reason,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    _formatDate(report.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Description Preview
              Text(
                'Description',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                report.description,
                style: const TextStyle(fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // View Details Button
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _showReportDetails(report, reportId),
                  style: TextButton.styleFrom(
                    foregroundColor: AdminReportsScreen._primaryColor,
                  ),
                  child: const Text('View Details →'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReportDetails(Report report, String reportId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildReportDetailsSheet(report, reportId),
    );
  }

  Widget _buildReportDetailsSheet(Report report, String reportId) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: scrollController,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Report Details',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Status
              _buildDetailSection(
                'Status',
                report.status.toUpperCase(),
                backgroundColor: _getStatusColor(
                  report.status,
                ).withValues(alpha: 0.1),
                textColor: _getStatusColor(report.status),
              ),
              const SizedBox(height: 16),

              // Food and Restaurant
              _buildDetailSection('Food Item', report.foodName),
              const SizedBox(height: 12),
              _buildDetailSection('Restaurant', report.restaurantName),
              const SizedBox(height: 16),

              // Reason
              _buildDetailSection('Reason', report.reason),
              const SizedBox(height: 16),

              // Description
              _buildDetailSection(
                'Description',
                report.description,
                isLarge: true,
              ),
              const SizedBox(height: 16),

              // Date
              _buildDetailSection(
                'Reported On',
                _formatDetailedDate(report.createdAt),
              ),
              const SizedBox(height: 16),

              // Reviewed Info (if applicable)
              if (report.status != 'pending') ...[
                _buildDetailSection(
                  'Reviewed By',
                  report.reviewedBy ?? 'Unknown',
                ),
                const SizedBox(height: 12),
                if (report.adminNotes != null && report.adminNotes!.isNotEmpty)
                  _buildDetailSection(
                    'Admin Notes',
                    report.adminNotes!,
                    isLarge: true,
                  ),
                const SizedBox(height: 16),
              ],

              // Action Buttons
              if (report.status == 'pending') ...[
                FilledButton(
                  onPressed: () => _markAsReviewed(reportId),
                  style: FilledButton.styleFrom(
                    backgroundColor: AdminReportsScreen._primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Mark as Reviewed'),
                ),
                const SizedBox(height: 12),
              ],
              if (report.status == 'reviewed') ...[
                FilledButton(
                  onPressed: () => _markAsResolved(reportId),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Mark as Resolved'),
                ),
                const SizedBox(height: 12),
              ],

              // Suspend Restaurant Button
              FilledButton(
                onPressed: () => _showSuspendConfirmation(report.restaurantId),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Suspend Restaurant'),
              ),
              const SizedBox(height: 12),

              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailSection(
    String label,
    String value, {
    bool isLarge = false,
    Color? backgroundColor,
    Color? textColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: isLarge ? 13 : 14,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _markAsReviewed(String reportId) async {
    final adminId = _auth.currentUser?.uid ?? '';
    final notesController = TextEditingController();

    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Reviewed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add optional notes about this report:'),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              maxLines: 3,
              minLines: 2,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                hintText: 'Enter your notes...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AdminReportsScreen._primaryColor,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _reportService.markReportAsReviewed(
          reportId,
          adminId,
          adminNotes: notesController.text.trim().isEmpty
              ? null
              : notesController.text.trim(),
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report marked as reviewed'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }

    notesController.dispose();
  }

  Future<void> _markAsResolved(String reportId) async {
    final adminId = _auth.currentUser?.uid ?? '';

    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Resolved'),
        content: const Text(
          'Are you sure you want to mark this report as resolved?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _reportService.markReportAsResolved(reportId, adminId);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report marked as resolved'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showSuspendConfirmation(String restaurantId) async {
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suspend Restaurant'),
        content: const Text(
          'Are you sure you want to suspend this restaurant? This will prevent them from accepting new orders.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Suspend'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _reportService.suspendRestaurant(
          restaurantId,
          reason: 'Suspended due to food safety complaints',
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Restaurant suspended successfully'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );

        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'reviewed':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatDetailedDate(DateTime date) {
    return '${date.day} ${_getMonthName(date.month)} ${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}
