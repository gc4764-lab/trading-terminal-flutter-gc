// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/broker_provider.dart';
import '../widgets/broker_connection_list.dart';
import '../widgets/broker_auth_dialog.dart';
import '../services/broker_manager.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _displayNameController;
  
  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserProvider>(context, listen: false).currentUser;
    _displayNameController = TextEditingController(text: user?.displayName ?? '');
  }
  
  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (_isEditing)
            TextButton(
              onPressed: _saveProfile,
              child: const Text('Save'),
            )
          else
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: Consumer2<UserProvider, BrokerProvider>(
        builder: (context, userProvider, brokerProvider, _) {
          final user = userProvider.currentUser;
          if (user == null) {
            return const Center(child: Text('Not logged in'));
          }
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Avatar Section
                _buildAvatarSection(user, userProvider),
                
                const SizedBox(height: 24),
                
                // User Info Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _isEditing
                        ? _buildEditForm()
                        : _buildUserInfo(user),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Connected Brokers
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Connected Brokers',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        BrokerConnectionList(
                          connectedBrokers: user.connectedBrokers,
                          onConnect: _connectBroker,
                          onDisconnect: _disconnectBroker,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => _addBroker(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Connect New Broker'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Account Switcher (if multiple accounts)
                if (userProvider.accounts.length > 1)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Switch Account',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          ...userProvider.accounts.where((a) => a.id != user.id).map((account) {
                            return ListTile(
                              leading: const Icon(Icons.person_outline),
                              title: Text(account.displayName ?? account.username),
                              subtitle: Text(account.email),
                              onTap: () => userProvider.switchAccount(account.id),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                
                const SizedBox(height: 24),
                
                // Logout Button
                ElevatedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildAvatarSection(UserAccount user, UserProvider provider) {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage: user.avatarUrl != null
              ? NetworkImage(user.avatarUrl!)
              : null,
          child: user.avatarUrl == null
              ? Text(
                  user.displayName?.substring(0, 1).toUpperCase() ?? user.username.substring(0, 1).toUpperCase(),
                  style: const TextStyle(fontSize: 40),
                )
              : null,
        ),
        const SizedBox(height: 12),
        Text(
          user.displayName ?? user.username,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          user.email,
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
  
  Widget _buildUserInfo(UserAccount user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Username', user.username),
        const Divider(),
        _buildInfoRow('Email', user.email),
        const Divider(),
        _buildInfoRow('Member Since', _formatDate(user.createdAt)),
        const Divider(),
        _buildInfoRow('Last Login', _formatDate(user.lastLogin)),
      ],
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _displayNameController,
            decoration: const InputDecoration(
              labelText: 'Display Name',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter display name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          // Add more editable fields as needed
        ],
      ),
    );
  }
  
  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      Provider.of<UserProvider>(context, listen: false).updateProfile({
        'displayName': _displayNameController.text,
      });
      setState(() => _isEditing = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
    }
  }
  
  void _connectBroker(String brokerId) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => BrokerAuthDialog(brokerId: brokerId),
    );
    
    if (result == true) {
      // Refresh connected brokers list
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final brokerManager = BrokerManager();
      final connected = brokerManager.getConnectedBrokers();
      await userProvider.updateProfile({
        'connectedBrokers': connected,
      });
    }
  }
  
  void _disconnectBroker(String brokerId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect Broker'),
        content: Text('Are you sure you want to disconnect from $brokerId?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Disconnect', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      final brokerManager = BrokerManager();
      await brokerManager.disconnectBroker(brokerId);
      
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final connected = brokerManager.getConnectedBrokers();
      await userProvider.updateProfile({
        'connectedBrokers': connected,
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Disconnected from $brokerId')),
      );
    }
  }
  
  void _addBroker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => BrokerSelectionSheet(
        onSelect: _connectBroker,
      ),
    );
  }
  
  void _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      final provider = Provider.of<UserProvider>(context, listen: false);
      await provider.logout();
      
      // Navigate to login screen (you may need to implement a login screen)
      // For now, just show a snackbar and pop
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logged out')),
      );
      Navigator.pop(context);
    }
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class BrokerSelectionSheet extends StatelessWidget {
  final Function(String) onSelect;
  
  const BrokerSelectionSheet({Key? key, required this.onSelect}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final brokerManager = BrokerManager();
    final availableBrokers = brokerManager.getAllBrokers();
    
    return Container(
      height: 400,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Broker',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: availableBrokers.length,
              itemBuilder: (context, index) {
                final broker = availableBrokers[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Icon(_getBrokerIcon(broker.brokerId)),
                  ),
                  title: Text(broker.brokerName),
                  subtitle: Text(broker.brokerId.toUpperCase()),
                  onTap: () {
                    Navigator.pop(context);
                    onSelect(broker.brokerId);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  IconData _getBrokerIcon(String brokerId) {
    switch (brokerId) {
      case 'fyers':
        return Icons.trending_up;
      case 'angel_one':
        return Icons.angel;
      case 'sharekhan':
        return Icons.share;
      case 'binance':
        return Icons.currency_bitcoin;
      default:
        return Icons.account_balance;
    }
  }
}
