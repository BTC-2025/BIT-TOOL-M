import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/app_providers.dart';
import '../../core/models/app_models.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddEditContactDialog({ContactItem? contact}) {
    final nameController = TextEditingController(text: contact?.name ?? '');
    final compController = TextEditingController(text: contact?.company ?? 'Cliks Business');
    final roleController = TextEditingController(text: contact?.designation ?? 'Supplier');
    final phoneController = TextEditingController(text: contact?.phone ?? '');
    final emailController = TextEditingController(text: contact?.email ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            contact == null ? 'Add New Contact' : 'Edit Contact',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Color(0xFF0F172A),
            ),
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: compController,
                    decoration: InputDecoration(
                      labelText: 'Company / Source (e.g. Cliks Business)',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: roleController,
                    decoration: InputDecoration(
                      labelText: 'Role (e.g. Supplier, Customer, Chithappa)',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                final provider = context.read<ContactsProvider>();
                if (contact == null) {
                  final now = DateTime.now();
                  final dateStr = 'Added ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
                  final newContact = ContactItem(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    photoUrl: '',
                    name: name,
                    company: compController.text.trim().isEmpty ? 'Cliks Business' : compController.text.trim(),
                    designation: roleController.text.trim().isEmpty ? 'Supplier' : roleController.text.trim(),
                    phone: phoneController.text.trim(),
                    email: emailController.text.trim(),
                    department: 'Operations',
                    location: dateStr,
                    notes: '${compController.text.trim()} • $dateStr',
                  );
                  provider.addContact(newContact);
                } else {
                  // Update contact
                  provider.deleteContact(contact.id);
                  final updated = ContactItem(
                    id: contact.id,
                    photoUrl: contact.photoUrl,
                    name: name,
                    company: compController.text.trim().isEmpty ? contact.company : compController.text.trim(),
                    designation: roleController.text.trim().isEmpty ? contact.designation : roleController.text.trim(),
                    phone: phoneController.text.trim(),
                    email: emailController.text.trim(),
                    department: contact.department,
                    location: contact.location,
                    notes: contact.notes,
                    isFavorite: contact.isFavorite,
                    isBlocked: contact.isBlocked,
                  );
                  provider.addContact(updated);
                }
                Navigator.pop(ctx);
              },
              child: Text(contact == null ? 'Save' : 'Update'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final contactsProvider = Provider.of<ContactsProvider>(context);
    final allContacts = contactsProvider.contacts;

    final query = _searchController.text.trim().toLowerCase();
    final filteredContacts = allContacts.where((c) {
      if (query.isEmpty) return true;
      return c.name.toLowerCase().contains(query) ||
          c.email.toLowerCase().contains(query) ||
          c.phone.toLowerCase().contains(query) ||
          c.designation.toLowerCase().contains(query);
    }).toList();

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

                // Contact Rows
                if (filteredContacts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        'No contacts found.',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                      ),
                    ),
                  )
                else
                  ...filteredContacts.map((c) => _buildContactRow(c)),
              ],
            ),
          ),
          const SizedBox(height: 32),
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
          const Icon(
            Icons.search_rounded,
            size: 18,
            color: Color(0xFF94A3B8),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search contacts...',
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF94A3B8),
                ),
              ),
              style: const TextStyle(fontSize: 13),
              onChanged: (_) => setState(() {}),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: () => _showAddEditContactDialog(),
      icon: const Icon(Icons.add, size: 18),
      label: const Text(
        'New Contact',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
        ),
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

  Widget _buildContactRow(ContactItem contact) {
    final initial = contact.name.isNotEmpty
        ? contact.name.trim()[0].toUpperCase()
        : '?';

    final sourceText = contact.notes.isNotEmpty
        ? contact.notes
        : '${contact.company} • Added 18/09/2026';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Name Column with Avatar & App Source
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
                        contact.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 7,
                              color: Colors.white,
                            ),
                          ),
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
                  ),
                ),
              ],
            ),
          ),

          // Contact Info Column (Email + Phone)
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                        contact.email.isNotEmpty
                            ? contact.email
                            : 'aruntest@bnxmail.com',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF475569),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
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
                        contact.phone.isNotEmpty
                            ? contact.phone
                            : '8984724747',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF475569),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Role Column (Pill Badge)
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                    Text(
                      contact.designation.isNotEmpty
                          ? contact.designation
                          : 'Supplier',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
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
                  onTap: () {
                    context.read<ContactsProvider>().deleteContact(contact.id);
                  },
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
}
