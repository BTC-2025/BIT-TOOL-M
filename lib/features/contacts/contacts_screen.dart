import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/app_providers.dart';
import '../../core/models/app_models.dart';
import '../../core/widgets/neumorphic_widgets.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _compController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  void _showAddContactDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Contact'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NeumorphicTextField(
                  controller: _nameController,
                  hintText: 'Name',
                ),
                const SizedBox(height: 12),
                NeumorphicTextField(
                  controller: _compController,
                  hintText: 'Company',
                ),
                const SizedBox(height: 12),
                NeumorphicTextField(
                  controller: _phoneController,
                  hintText: 'Phone',
                ),
                const SizedBox(height: 12),
                NeumorphicTextField(
                  controller: _emailController,
                  hintText: 'Email',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            NeumorphicButton(
              onPressed: () {
                final newContact = ContactItem(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  photoUrl: '',
                  name: _nameController.text,
                  company: _compController.text,
                  designation: 'Engineer',
                  phone: _phoneController.text,
                  email: _emailController.text,
                  department: 'R&D',
                  location: 'San Francisco, USA',
                  notes: '',
                );
                context.read<ContactsProvider>().addContact(newContact);
                _nameController.clear();
                _compController.clear();
                _phoneController.clear();
                _emailController.clear();
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final contactsProvider = Provider.of<ContactsProvider>(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Company Directory',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              NeumorphicButton(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                onPressed: _showAddContactDialog,
                color: Theme.of(context).primaryColor,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_add, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Add',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          contactsProvider.contacts.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Text('No contacts registered.'),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: contactsProvider.contacts.length,
                  itemBuilder: (context, i) {
                    final contact = contactsProvider.contacts[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: NeumorphicCard(
                        borderRadius: 16,
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Theme.of(
                                context,
                              ).primaryColor.withValues(alpha: 0.1),
                              child: Text(
                                contact.name[0],
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold,
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
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${contact.designation} • ${contact.company}',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  // Action buttons aligned horizontally under text to prevent side squeezing
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () => contactsProvider
                                            .toggleFavorite(contact.id),
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: contact.isFavorite
                                                ? Colors.red.withValues(
                                                    alpha: 0.1,
                                                  )
                                                : Colors.grey.withValues(
                                                    alpha: 0.1,
                                                  ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            contact.isFavorite
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            size: 16,
                                            color: contact.isFavorite
                                                ? Colors.red
                                                : Colors.grey,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      GestureDetector(
                                        onTap: () => contactsProvider
                                            .toggleBlocked(contact.id),
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: contact.isBlocked
                                                ? Colors.red.withValues(
                                                    alpha: 0.1,
                                                  )
                                                : Colors.grey.withValues(
                                                    alpha: 0.1,
                                                  ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            contact.isBlocked
                                                ? Icons.block
                                                : Icons.check_circle_outline,
                                            size: 16,
                                            color: contact.isBlocked
                                                ? Colors.red
                                                : Colors.grey,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      GestureDetector(
                                        onTap: () => contactsProvider
                                            .deleteContact(contact.id),
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withValues(
                                              alpha: 0.1,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.delete_outline,
                                            size: 16,
                                            color: Colors.red,
                                          ),
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
                    );
                  },
                ),
        ],
      ),
    );
  }
}
