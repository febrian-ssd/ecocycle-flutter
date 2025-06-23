// lib/screens/ecopay_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:ecocycle_app/providers/auth_provider.dart';
import 'package:ecocycle_app/services/api_service.dart';
import 'package:ecocycle_app/models/transaction.dart';
import 'package:ecocycle_app/screens/isi_saldo_screen.dart';
import 'package:ecocycle_app/screens/transfer_screen.dart';
import 'package:ecocycle_app/screens/tukar_koin_screen.dart';

class EcoPayPage extends StatefulWidget {
  const EcoPayPage({super.key});

  @override
  State<EcoPayPage> createState() => _EcoPayPageState();
}

class _EcoPayPageState extends State<EcoPayPage> {
  final ApiService _apiService = ApiService();
  final _rpFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  
  double _balanceRp = 0;
  int _balanceCoins = 0;
  List<Transaction> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }

  Future<void> _loadWalletData() async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token != null) {
        // Load wallet data
        final walletData = await _apiService.getWallet(token);
        final transactions = await _apiService.getTransactions(token);
        
        setState(() {
          _balanceRp = (walletData['balance_rp'] ?? 0).toDouble();
          _balanceCoins = walletData['balance_coins'] ?? 0;
          _transactions = transactions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load wallet: $e')),
        );
      }
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    await _loadWalletData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    _buildWalletCard(),
                    const SizedBox(height: 24),
                    _buildActionButtons(context),
                    const SizedBox(height: 24),
                    _buildTransactionHistory(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120.0,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF004d00),
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'EcoPay',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF004d00), Color(0xFF006600)],
            ),
          ),
        ),
      ),
      automaticallyImplyLeading: false,
    );
  }

  Widget _buildWalletCard() {
    if (_isLoading) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF00695C), Color(0xFF004D40)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF00695C), Color(0xFF004D40)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_balanceCoins',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'EcoCoins',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.eco,
                  color: Colors.amber,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white24),
          const SizedBox(height: 16),
          const Text(
            'Saldo Anda',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF004D40),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24),
            ),
            child: Text(
              _rpFormatter.format(_balanceRp),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _actionButton(
            'Top Up',
            Icons.add_circle_outline,
            Colors.blue,
            () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const IsiSaldoScreen()),
              );
              if (result == true) _refreshData();
            },
          ),
          _actionButton(
            'Transfer',
            Icons.send_outlined,
            Colors.orange,
            () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TransferScreen()),
              );
              if (result == true) _refreshData();
            },
          ),
          _actionButton(
            'Tukar Koin',
            Icons.swap_horiz,
            Colors.amber,
            () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TukarKoinScreen()),
              );
              if (result == true) _refreshData();
            },
          ),
        ],
      ),
    );
  }

  Widget _actionButton(String title, IconData icon, Color color, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionHistory() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        leading: const Icon(Icons.history, color: Colors.white),
        title: const Text(
          'Riwayat Transaksi',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        trailing: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
        iconColor: Colors.white,
        collapsedIconColor: Colors.white,
        backgroundColor: Colors.transparent,
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _transactions.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'Belum ada transaksi',
                          style: TextStyle(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _transactions.take(5).length,
                        separatorBuilder: (context, index) => 
                            Divider(color: Colors.grey[700], height: 1),
                        itemBuilder: (context, index) {
                          final trx = _transactions[index];
                          return _buildTransactionItem(trx);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    IconData icon;
    Color iconColor;
    String amountText;
    bool isPositive = false;

    switch (transaction.type) {
      case 'topup':
      case 'manual_topup':
        icon = Icons.add_circle;
        iconColor = Colors.green;
        amountText = _rpFormatter.format(transaction.amountRp ?? 0);
        isPositive = true;
        break;
      case 'transfer_out':
        icon = Icons.send;
        iconColor = Colors.red;
        amountText = _rpFormatter.format(transaction.amountRp ?? 0);
        break;
      case 'coin_exchange_to_rp':
        icon = Icons.swap_horiz;
        iconColor = Colors.amber;
        amountText = '${transaction.amountCoins} koin → ${_rpFormatter.format(transaction.amountRp ?? 0)}';
        break;
      case 'scan_reward':
        icon = Icons.eco;
        iconColor = Colors.amber;
        amountText = '+${transaction.amountCoins} koin';
        isPositive = true;
        break;
      default:
        icon = Icons.receipt;
        iconColor = Colors.grey;
        amountText = transaction.amountRp != null 
            ? _rpFormatter.format(transaction.amountRp!)
            : '${transaction.amountCoins} koin';
    }

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        _getTransactionTitle(transaction.type),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        DateFormat('dd MMM yyyy, HH:mm').format(transaction.createdAt),
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
      trailing: Text(
        amountText,
        style: TextStyle(
          color: isPositive ? Colors.green : Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  String _getTransactionTitle(String type) {
    switch (type) {
      case 'topup':
      case 'manual_topup':
        return 'Top Up Saldo';
      case 'transfer_out':
        return 'Transfer Keluar';
      case 'coin_exchange_to_rp':
        return 'Tukar Koin';
      case 'scan_reward':
        return 'Reward Scan';
      default:
        return 'Transaksi';
    }
  }
}