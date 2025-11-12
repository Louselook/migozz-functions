import 'package:flutter/material.dart';
import 'package:migozz_app/features/chat/data/domain/models/chat_preview.dart';
import 'package:migozz_app/features/chat/presentation/components/chat_list_item.dart';

/// Pantalla de lista de chats - SOLO UI (sin lógica de backend)
class ChatsListScreen extends StatefulWidget {
  final String username;

  const ChatsListScreen({super.key, required this.username});

  @override
  State<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // 🎨 Datos mock solo para visualización
  List<ChatPreview> _getMockChats() {
    return [
      ChatPreview(
        userId: '1',
        displayName: 'Javier Cole',
        username: 'javicole',
        lastMessage: 'He liked a message',
        timeAgo: '2h',
        isVerified: true,
        isOnline: true,
      ),
      ChatPreview(
        userId: '2',
        displayName: 'Emily Dawson',
        username: 'emidawson',
        lastMessage: 'Sent ago a H',
        timeAgo: '4h',
        isVerified: true,
        isOnline: false,
      ),
      ChatPreview(
        userId: '3',
        displayName: 'Eli West',
        username: 'westview',
        lastMessage: 'Sent ago a T',
        timeAgo: '3h',
        isVerified: true,
        isOnline: false,
      ),
      ChatPreview(
        userId: '4',
        displayName: 'André Knox',
        username: 'andreknox',
        lastMessage: 'Sent a photo · 13 hrs',
        timeAgo: '13h',
        isVerified: true,
        isOnline: false,
      ),
      ChatPreview(
        userId: '5',
        displayName: 'Cameron Lane',
        username: 'camcam',
        lastMessage: 'I have an update i wanted',
        timeAgo: '1d',
        isVerified: true,
        isOnline: true,
      ),
      ChatPreview(
        userId: '6',
        displayName: 'Hailey Morgan',
        username: 'hailey',
        lastMessage: 'That sounds great!',
        timeAgo: '2d',
        isVerified: true,
        isOnline: false,
      ),
      ChatPreview(
        userId: '7',
        displayName: 'Madison Clarke',
        username: 'madcl',
        lastMessage: 'She reacted to your story. Amazing photo',
        timeAgo: '2d',
        isVerified: false,
        isOnline: false,
      ),
      ChatPreview(
        userId: '8',
        displayName: 'Taylor Grant',
        username: 'tgrant',
        lastMessage: 'I will be attentive',
        timeAgo: '1w',
        isVerified: true,
        isOnline: false,
      ),
    ];
  }

  List<ChatPreview> _getFilteredChats() {
    final chats = _getMockChats();
    if (_searchQuery.isEmpty) return chats;

    return chats.where((chat) {
      return chat.displayName.toLowerCase().contains(_searchQuery) ||
          chat.username.toLowerCase().contains(_searchQuery) ||
          chat.lastMessage.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Barra de búsqueda
          _buildSearchBar(),

          // Tabs
          _buildTabs(),

          // Lista de chats
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab Main
                _buildChatList(_getFilteredChats()),

                // Tab Requests
                _buildEmptyState('No message requests'),

                // Tab General
                _buildEmptyState('No general messages'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1C1C1E),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        '@${widget.username}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_square, color: Colors.white),
          onPressed: () {
            debugPrint('Nuevo mensaje');
          },
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search',
          hintStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          // 🔧 Dropdown de filtros (sin cambios)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.tune, color: Colors.grey[400], size: 18),
                const SizedBox(width: 4),
                Icon(Icons.arrow_drop_down, color: Colors.grey[400], size: 18),
              ],
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: SizedBox(
              height: 38, // altura del tab (ajusta si quieres más/menos)
              child: TabBar(
                controller: _tabController,
                // clave: usar TabBarIndicatorSize.tab
                indicatorSize: TabBarIndicatorSize.tab,
                // quitar paddings para que la BoxDecoration ocupe todo el tab
                indicatorPadding: EdgeInsets.zero,
                labelPadding: EdgeInsets.zero,
                // indicador como "pill" que ocupa todo el tab
                indicator: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                // estilos de texto
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey[400],
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  // Si quieres algo de padding interior al texto, envolver cada Tab
                  Tab(child: Center(child: Text('Main'))),
                  Tab(child: Center(child: Text('Requests'))),
                  Tab(child: Center(child: Text('General'))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList(List<ChatPreview> chats) {
    if (chats.isEmpty) {
      return _buildEmptyState('No messages yet');
    }

    return ListView.builder(
      itemCount: chats.length,
      itemBuilder: (context, index) {
        final chat = chats[index];
        return ChatListItem(
          chat: chat,
          onTap: () {
            // 🎨 Solo imprimir por ahora
            debugPrint('Abrir chat con: ${chat.displayName}');
            // Navigator.push(...);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[700]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }
}
