import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tool_module.dart';
import '../providers/app_state.dart';

class ExpenseSplitterModule extends ToolModule {
  @override
  String get title => 'Split-It';

  @override
  IconData get icon => Icons.receipt_long_outlined;

  @override
  Widget buildBody(BuildContext context) => const _ExpenseSplitterBody();
}

// --------------- Stateful Widget ---------------

class _ExpenseSplitterBody extends StatefulWidget {
  const _ExpenseSplitterBody();

  @override
  State<_ExpenseSplitterBody> createState() => _ExpenseSplitterBodyState();
}

class _ExpenseSplitterBodyState extends State<_ExpenseSplitterBody> {
  final _totalController = TextEditingController();
  final _tipController = TextEditingController(text: '10');
  final _nameController = TextEditingController();

  final List<String> _people = [];
  double _amountPerPerson = 0;
  double _totalWithTip = 0;
  bool _hasResult = false;

  @override
  void dispose() {
    _totalController.dispose();
    _tipController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _addPerson() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showSnack('Please enter a name first!');
      return;
    }
    setState(() {
      _people.add(name);
      _nameController.clear();
    });
  }

  void _removePerson(int index) {
    setState(() {
      _people.removeAt(index);
      _hasResult = false;
    });
  }

  void _calculate() {
    if (_totalController.text.trim().isEmpty) {
      _showSnack('⚠️ Total amount cannot be empty!');
      return;
    }
    if (_people.isEmpty) {
      _showSnack('⚠️ Pax is 0 — add at least one person!');
      return;
    }

    final total = double.tryParse(_totalController.text) ?? 0;
    final tip = double.tryParse(_tipController.text) ?? 0;

    if (total <= 0) {
      _showSnack('⚠️ Enter a valid total amount.');
      return;
    }

    final withTip = total * (1 + tip / 100);
    setState(() {
      _totalWithTip = withTip;
      _amountPerPerson = withTip / _people.length;
      _hasResult = true;
    });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = state.theme;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ---- Banner ----
        _SectionCard(
          accentColor: theme.accent,
          primaryColor: theme.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '💰 Bill Details',
                style: TextStyle(
                  color: theme.accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _totalController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Total Amount (₱)',
                        prefixIcon: Icon(Icons.money, color: Colors.white38),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _tipController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Tip %',
                        prefixIcon: Icon(Icons.percent, color: Colors.white38),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ---- People List ----
        _SectionCard(
          accentColor: theme.accent,
          primaryColor: theme.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '👥 People (${_people.length})',
                    style: TextStyle(
                      color: theme.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (_people.isNotEmpty)
                    Text(
                      'Pax: ${_people.length}',
                      style: TextStyle(
                        color: theme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Add person row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        prefixIcon: Icon(
                          Icons.person_add,
                          color: Colors.white38,
                        ),
                      ),
                      onSubmitted: (_) => _addPerson(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _addPerson,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 18,
                      ),
                    ),
                    child: const Icon(Icons.add),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              if (_people.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text(
                      'No one added yet. Add people above! 👆',
                      style: TextStyle(color: Colors.white38),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _people.length,
                  itemBuilder: (ctx, i) => _PersonTile(
                    name: _people[i],
                    index: i,
                    accentColor: theme.accent,
                    primaryColor: theme.primary,
                    onDelete: () => _removePerson(i),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ---- Calculate Button ----
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _calculate,
            icon: const Icon(Icons.calculate_outlined),
            label: const Text(
              'CALCULATE SPLIT',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // ---- Results ----
        if (_hasResult)
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.primary.withOpacity(0.3),
                  theme.secondary.withOpacity(0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.accent.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Text(
                  '🎉 Split Result',
                  style: TextStyle(
                    color: theme.accent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _ResultRow(
                  label: 'Total (with tip)',
                  value: '₱${_totalWithTip.toStringAsFixed(2)}',
                  color: Colors.white70,
                ),
                const SizedBox(height: 8),
                _ResultRow(
                  label: 'Each person pays',
                  value: '₱${_amountPerPerson.toStringAsFixed(2)}',
                  color: theme.accent,
                  large: true,
                ),
                const Divider(color: Colors.white12, height: 24),
                ...List.generate(
                  _people.length,
                  (i) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.person, size: 16, color: theme.accent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _people[i],
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                        Text(
                          '₱${_amountPerPerson.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// --------------- Helper Widgets ---------------

class _SectionCard extends StatelessWidget {
  final Widget child;
  final Color accentColor;
  final Color primaryColor;

  const _SectionCard({
    required this.child,
    required this.accentColor,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withOpacity(0.3)),
      ),
      child: child,
    );
  }
}

class _PersonTile extends StatelessWidget {
  final String name;
  final int index;
  final Color accentColor;
  final Color primaryColor;
  final VoidCallback onDelete;

  const _PersonTile({
    required this.name,
    required this.index,
    required this.accentColor,
    required this.primaryColor,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: primaryColor.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: accentColor.withOpacity(0.2),
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: accentColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.redAccent,
              size: 20,
            ),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool large;

  const _ResultRow({
    required this.label,
    required this.value,
    required this.color,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white54, fontSize: large ? 15 : 14),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: large ? 22 : 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
