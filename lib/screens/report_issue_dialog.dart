import 'package:flutter/material.dart';
import 'package:save_bite/services/report_service.dart';

class ReportIssueDialog extends StatefulWidget {
  final String orderId;
  final String foodName;
  final String restaurantName;
  final String restaurantId;
  final String foodId;
  final String userId;
  final VoidCallback onSuccess;

  const ReportIssueDialog({
    super.key,
    required this.orderId,
    required this.foodName,
    required this.restaurantName,
    required this.restaurantId,
    required this.foodId,
    required this.userId,
    required this.onSuccess,
  });

  @override
  State<ReportIssueDialog> createState() => _ReportIssueDialogState();
}

class _ReportIssueDialogState extends State<ReportIssueDialog> {
  static const Color _primaryColor = Color(0xFF2E7D32);

  final ReportService _reportService = ReportService();
  final TextEditingController _descriptionController = TextEditingController();

  String _selectedReason = 'Food poisoning / sickness';
  bool _isSubmitting = false;

  final List<String> _reasons = [
    'Food poisoning / sickness',
    'Expired food',
    'Bad food quality',
    'Incorrect item',
    'Other',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    final description = _descriptionController.text.trim();

    if (description.isEmpty) {
      _showSnackBar('Please describe the issue');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _reportService.submitReport(
        userId: widget.userId,
        restaurantId: widget.restaurantId,
        restaurantName: widget.restaurantName,
        foodId: widget.foodId,
        foodName: widget.foodName,
        orderId: widget.orderId,
        reason: _selectedReason,
        description: description,
      );

      if (!mounted) return;

      _showSnackBar('Report submitted successfully', isError: false);
      widget.onSuccess();

      // Close dialog after delay
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Report an Issue',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
              const SizedBox(height: 20),

              // Food and Restaurant Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Food Item',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.foodName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Restaurant',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.restaurantName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Reason Dropdown
              Text(
                'Reason for Report',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButton<String>(
                  value: _selectedReason,
                  isExpanded: true,
                  underline: const SizedBox(),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  items: _reasons
                      .map(
                        (reason) => DropdownMenuItem(
                          value: reason,
                          child: Text(reason),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedReason = value);
                    }
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Description Text Field
              Text(
                'Describe the Issue',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                maxLines: 5,
                minLines: 3,
                enabled: !_isSubmitting,
                decoration: InputDecoration(
                  hintText:
                      'Please provide details about the issue you experienced...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: _primaryColor,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isSubmitting ? null : _submitReport,
                      style: FilledButton.styleFrom(
                        backgroundColor: _primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text('Submit Report'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
