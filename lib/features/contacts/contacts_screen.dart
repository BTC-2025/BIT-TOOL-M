import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api/api_exceptions.dart';
import '../../core/models/contact_model.dart';
import '../../core/providers/contacts_provider.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<ContactsProvider>();
      if (provider.status == ContactsStatus.initial) {
        provider.fetchContacts();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddEditContactDialog({ContactModel? contact}) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final nameController = TextEditingController(text: contact?.fullName ?? '');
    final emailController = TextEditingController(text: contact?.email ?? '');
    final phoneController = TextEditingController(text: contact?.phone ?? '');
    final companyController =
        TextEditingController(text: contact?.company ?? '');
    final notesController = TextEditingController(text: contact?.notes ?? '');

    String selectedRole =
        contact != null && contact.role.isNotEmpty
            ? contact.role
            : 'Customer';
    final List<String> roleOptions = [
      'Customer',
      'Supplier',
      'Employee',
      'Partner',
      'Other',
    ];
    if (!roleOptions.contains(selectedRole)) {
      roleOptions.insert(0, selectedRole);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool isSubmitting = false;
        String? dialogError;

        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
            final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
            final labelColor =
                isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
            final fieldBg = isDark ? const Color(0xFF0F172A) : Colors.white;
            final borderColor =
                isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

            InputDecoration buildFieldDecoration(String hint) {
              return InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: isDark
                      ? const Color(0xFF64748B)
                      : const Color(0xFF94A3B8),
                  fontSize: 14,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                filled: true,
                fillColor: fieldBg,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF2563EB),
                    width: 1.5,
                  ),
                ),
              );
            }

            return Dialog(
              backgroundColor: cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: isDark
                    ? const BorderSide(color: Color(0xFF334155))
                    : BorderSide.none,
              ),
              child: Container(
                width: 480,
                padding: const EdgeInsets.all(28),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Title + Close Icon
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            contact == null
                                ? 'Create New Contact'
                                : 'Edit Contact',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: textColor,
                            ),
                          ),
                          InkWell(
                            onTap: isSubmitting
                                ? null
                                : () => Navigator.pop(ctx),
                            borderRadius: BorderRadius.circular(10),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.close_rounded,
                                size: 20,
                                color: labelColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Error banner if request failed
                      if (dialogError != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFECACA)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: Color(0xFFEF4444),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  dialogError!,
                                  style: const TextStyle(
                                    color: Color(0xFFB91C1C),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // FULL NAME *
                      Text(
                        'FULL NAME *',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: labelColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: nameController,
                        style: TextStyle(color: textColor, fontSize: 14),
                        decoration: buildFieldDecoration('e.g. John Doe'),
                      ),
                      const SizedBox(height: 18),

                      // EMAIL ADDRESS
                      Text(
                        'EMAIL ADDRESS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: labelColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(color: textColor, fontSize: 14),
                        decoration: buildFieldDecoration('john@example.com'),
                      ),
                      const SizedBox(height: 18),

                      // PHONE NUMBER + ROLE ROW
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'PHONE NUMBER',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                    color: labelColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: phoneController,
                                  keyboardType: TextInputType.phone,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 14,
                                  ),
                                  decoration: buildFieldDecoration(
                                    '+1 (555) 000-0000',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ROLE',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                    color: labelColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  initialValue: selectedRole,
                                  dropdownColor: cardBg,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 14,
                                  ),
                                  decoration: buildFieldDecoration(''),
                                  icon: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: labelColor,
                                  ),
                                  items: roleOptions.map((role) {
                                    return DropdownMenuItem<String>(
                                      value: role,
                                      child: Text(
                                        role,
                                        style: TextStyle(color: textColor),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: isSubmitting
                                      ? null
                                      : (val) {
                                          if (val != null) {
                                            setDialogState(() => selectedRole = val);
                                          }
                                        },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // COMPANY FIELD
                      Text(
                        'COMPANY',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: labelColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: companyController,
                        style: TextStyle(color: textColor, fontSize: 14),
                        decoration: buildFieldDecoration('e.g. Acme Corp'),
                      ),
                      const SizedBox(height: 18),

                      // NOTES FIELD
                      Text(
                        'NOTES',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: labelColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: notesController,
                        maxLines: 2,
                        style: TextStyle(color: textColor, fontSize: 14),
                        decoration: buildFieldDecoration('Additional notes...'),
                      ),
                      const SizedBox(height: 28),

                      // Actions: Cancel & Create/Update Contact
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: labelColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 13,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    final fullName = nameController.text.trim();
                                    if (fullName.isEmpty) {
                                      setDialogState(() {
                                        dialogError = 'Full Name is required.';
                                      });
                                      return;
                                    }

                                    final email = emailController.text.trim();
                                    if (email.isNotEmpty &&
                                        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                                      setDialogState(() {
                                        dialogError = 'Please enter a valid email address.';
                                      });
                                      return;
                                    }

                                    setDialogState(() {
                                      isSubmitting = true;
                                      dialogError = null;
                                    });

                                    final (firstName, lastName) =
                                        ContactModel.parseFullName(fullName);
                                    final provider = context.read<ContactsProvider>();

                                    try {
                                      if (contact == null) {
                                        await provider.createContact(
                                          firstName: firstName,
                                          lastName: lastName,
                                          email: email,
                                          phone: phoneController.text.trim(),
                                          company: companyController.text.trim(),
                                          notes: notesController.text.trim(),
                                          role: selectedRole,
                                        );
                                      } else {
                                        await provider.updateContact(
                                          contact.id,
                                          firstName: firstName,
                                          lastName: lastName,
                                          email: email,
                                          phone: phoneController.text.trim(),
                                          company: companyController.text.trim(),
                                          notes: notesController.text.trim(),
                                          role: selectedRole,
                                        );
                                      }

                                      if (dialogContext.mounted) {
                                        Navigator.pop(dialogContext);
                                      }
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              contact == null
                                                  ? 'Contact created successfully.'
                                                  : 'Contact updated successfully.',
                                            ),
                                            backgroundColor:
                                                const Color(0xFF10B981),
                                          ),
                                        );
                                      }
                                    } on ApiException catch (e) {
                                      if (dialogContext.mounted) {
                                        setDialogState(() {
                                          dialogError = e.message;
                                          isSubmitting = false;
                                        });
                                      }
                                    } catch (_) {
                                      if (dialogContext.mounted) {
                                        setDialogState(() {
                                          dialogError =
                                              'Failed to save contact. Please check your connection and retry.';
                                          isSubmitting = false;
                                        });
                                      }
                                    }
                                  },
                            child: isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Text(
                                    contact == null
                                        ? 'Create Contact'
                                        : 'Update Contact',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteContact(ContactModel contact) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final labelColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    showDialog(
      context: context,
      builder: (ctx) {
        bool isDeleting = false;
        String? deleteError;

        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: isDark
                    ? const BorderSide(color: Color(0xFF334155))
                    : BorderSide.none,
              ),
              title: Text(
                'Delete Contact',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: textColor,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Are you sure you want to delete "${contact.fullName}"? This action cannot be undone.',
                    style: TextStyle(color: labelColor, fontSize: 14),
                  ),
                  if (deleteError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      deleteError!,
                      style: const TextStyle(
                        color: Color(0xFFEF4444),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.pop(dialogCtx),
                  child: Text('Cancel', style: TextStyle(color: labelColor)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  onPressed: isDeleting
                      ? null
                      : () async {
                          setDialogState(() {
                            isDeleting = true;
                            deleteError = null;
                          });

                          try {
                            final success = await context
                                .read<ContactsProvider>()
                                .deleteContact(contact.id);

                            if (dialogCtx.mounted) {
                              Navigator.pop(dialogCtx);
                            }
                            if (mounted && success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Contact deleted successfully.'),
                                  backgroundColor: Color(0xFF10B981),
                                ),
                              );
                            }
                          } on ApiException catch (e) {
                            if (dialogCtx.mounted) {
                              setDialogState(() {
                                isDeleting = false;
                                deleteError = e.message;
                              });
                            }
                          } catch (_) {
                            if (dialogCtx.mounted) {
                              setDialogState(() {
                                isDeleting = false;
                                deleteError =
                                    'Failed to delete contact. Please check your connection and retry.';
                              });
                            }
                          }
                        },
                  child: isDeleting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Delete',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── Header ──────────────────────────────────────────────────────────
          _buildHeader(),
          const SizedBox(height: 24),

          // ─── Table Card Container ────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Table Header Row
                _buildTableHeader(),

                // Table Content (Loading / Error / Empty / Rows)
                Consumer<ContactsProvider>(
                  builder: (context, provider, _) {
                    return _buildTableContent(provider);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildTableContent(ContactsProvider provider) {
    if (provider.isLoading && !provider.isRefreshing) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                ),
              ),
              SizedBox(height: 14),
              Text(
                'Loading contacts...',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.hasError) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFEF4444),
                size: 36,
              ),
              const SizedBox(height: 12),
              Text(
                provider.errorMessage ?? 'Unable to load contacts.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                onPressed: () => provider.fetchContacts(forceRefresh: true),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final contacts = provider.filteredContacts;

    if (contacts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.people_outline_rounded,
                color: Color(0xFF94A3B8),
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                provider.searchQuery.isNotEmpty
                    ? 'No contacts match "${provider.searchQuery}".'
                    : 'No contacts found.',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        ...contacts.map((c) => _buildContactRow(c)),
        if (provider.totalPages > 1) _buildPaginationBar(provider),
      ],
    );
  }

  Widget _buildPaginationBar(ContactsProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Page ${provider.currentPage} of ${provider.totalPages} (${provider.totalRecords} total)',
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 20),
                onPressed: provider.hasPreviousPage
                    ? () => provider.fetchContacts(page: provider.currentPage - 1)
                    : null,
                splashRadius: 18,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, size: 20),
                onPressed: provider.hasNextPage
                    ? () => provider.fetchContacts(page: provider.currentPage + 1)
                    : null,
                splashRadius: 18,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 700;

        return isCompact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderTitle(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildSearchBar()),
                      const SizedBox(width: 10),
                      _buildAddButton(),
                    ],
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: _buildHeaderTitle()),
                  const SizedBox(width: 16),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildSearchBar(),
                      const SizedBox(width: 12),
                      _buildAddButton(),
                    ],
                  ),
                ],
              );
      },
    );
  }

  Widget _buildHeaderTitle() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.people_alt_rounded,
            color: Color(0xFF2563EB),
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Contact Management',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 2),
              Text(
                'Manage your contacts across all integrated applications.',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      width: 240,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search contacts...',
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              ),
              style: const TextStyle(fontSize: 13),
              onChanged: (val) {
                context.read<ContactsProvider>().setSearchQuery(val);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () => _showAddEditContactDialog(),
      icon: const Icon(Icons.add, size: 18),
      label: const Text(
        'New Contact',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'NAME',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'CONTACT INFO',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'ROLE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              'ACTIONS',
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(ContactModel contact) {
    final initial = contact.initial;

    // Prioritize actual integrated application source, notes, or company; never fake fallback dates
    final sourceText = contact.applicationName.trim().isNotEmpty
        ? contact.applicationName.trim()
        : (contact.notes.trim().isNotEmpty
            ? contact.notes.trim()
            : (contact.company.trim().isNotEmpty ? contact.company.trim() : ''));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
      ),
      child: Row(
        children: [
          // Name Column with Avatar & Real Notes/Company
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFDBEAFE),
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.fullName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (sourceText.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            _buildSourceLogo(sourceText),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                sourceText,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Contact Info Column (Email + Phone, strictly verified without fake values)
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (contact.email.trim().isNotEmpty)
                  Row(
                    children: [
                      const Icon(
                        Icons.mail_outline_rounded,
                        size: 14,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          contact.email.trim(),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF475569),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                if (contact.email.trim().isNotEmpty &&
                    contact.phone.trim().isNotEmpty)
                  const SizedBox(height: 4),
                if (contact.phone.trim().isNotEmpty)
                  Row(
                    children: [
                      const Icon(
                        Icons.phone_outlined,
                        size: 14,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          contact.phone.trim(),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF475569),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                if (contact.email.trim().isEmpty &&
                    contact.phone.trim().isEmpty)
                  const Text(
                    '—',
                    style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  ),
              ],
            ),
          ),

          // Role Column (Pill Badge)
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: (contact.role.trim().isNotEmpty ||
                      contact.company.trim().isNotEmpty)
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.account_balance_outlined,
                            size: 13,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              contact.role.trim().isNotEmpty
                                  ? contact.role.trim()
                                  : contact.company.trim(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF334155),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),

          // Actions Column
          SizedBox(
            width: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () => _showAddEditContactDialog(contact: contact),
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: () => _confirmDeleteContact(contact),
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceLogo(String sourceText) {
    final lower = sourceText.toLowerCase();
    String assetPath = 'assets/cliks_business_img.png';
    if (lower.contains('bnx')) {
      assetPath = 'assets/bnx_mail_logo.png';
    } else if (lower.contains('bit')) {
      assetPath = 'assets/bit_tool_logo.png';
    } else if (lower.contains('cliks business')) {
      assetPath = 'assets/cliks_business_img.png';
    } else if (lower.contains('cliks')) {
      assetPath = 'assets/cliks_logo.png';
    }

    return SizedBox(
      width: 14,
      height: 14,
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Container(
          width: 12,
          height: 12,
          decoration: const BoxDecoration(
            color: Color(0xFF10B981),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, size: 8, color: Colors.white),
        ),
      ),
    );
  }
}
