import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dartotsu/Api/Sources/Model/Source.dart';
import 'package:dartotsu/Preferences/PrefManager.dart';

class SettingsSourceScreen extends StatefulWidget {
  const SettingsSourceScreen({Key? key}) : super(key: key);

  @override
  State<SettingsSourceScreen> createState() => _SettingsSourceScreenState();
}

class _SettingsSourceScreenState extends State<SettingsSourceScreen> {
  List<Source> sources = [];
  String? globalDefaultSourceId;

  @override
  void initState() {
    super.initState();
    // Try to load sources from persistent storage
    final loadedSources = loadCustomData<List<dynamic>>('sources');
    if (loadedSources != null) {
      sources = loadedSources.map((e) => Source.fromJson(Map<String, dynamic>.from(e))).toList();
    } else {
      // Pre-populate with provided sources
      sources = [
        Source(
          id: 1,
          name: 'Hianime',
          baseUrls: [
            'https://hianime.pe',
            'https://hianimez.is',
          ],
        ),
        Source(
          id: 2,
          name: 'kaido',
          baseUrls: [
            'https://kaido.to',
          ],
        ),
        Source(
          id: 3,
          name: 'Aniplay',
          baseUrls: [
            'https://aniplaynow.live',
          ],
        ),
      ];
    }
    globalDefaultSourceId = loadCustomData<String>('global_default_source_id');
  }

  void saveGlobalDefaultSource(String? id) {
    setState(() {
      globalDefaultSourceId = id;
      saveCustomData<String>('global_default_source_id', id ?? '');
    });
  }

  void saveDomains(Source source, List<String> domains) {
    setState(() {
      source.baseUrls = List<String>.from(domains);
      // Save the updated sources list to persistent storage
      saveCustomData<List<Map<String, dynamic>>>(
        'sources',
        sources.map((s) => s.toJson()).toList(),
      );
    });
  }

  void addSource(String name, List<String> domains) {
    setState(() {
      final newId = (sources.isNotEmpty ? (sources.map((s) => s.id ?? 0).reduce((a, b) => a > b ? a : b) + 1 : 1);
      sources.add(Source(
        id: newId,
        name: name,
        baseUrls: domains,
      ));
      // Save the updated sources list to persistent storage
      saveCustomData<List<Map<String, dynamic>>>(
        'sources',
        sources.map((s) => s.toJson()).toList(),
      );
    });
  }

  void showAddSourceDialog() {
    final nameController = TextEditingController();
    final domainController = TextEditingController();
    List<String> domains = [];
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Source'),
          content: SizedBox(
            width: 350,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Source Name'),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: domainController,
                        decoration: const InputDecoration(hintText: 'Add domain (e.g. https://example.com)'),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        final text = domainController.text.trim();
                        if (text.isNotEmpty && !domains.contains(text)) {
                          domains.add(text);
                          domainController.clear();
                          setState(() {});
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    itemCount: domains.length,
                    itemBuilder: (context, i) => ListTile(
                      title: Text(domains[i]),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          domains.removeAt(i);
                          setState(() {});
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty && domains.isNotEmpty) {
                  addSource(nameController.text.trim(), domains);
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Source Management')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Global Default Anime Source', style: TextStyle(fontWeight: FontWeight.bold)),
          DropdownButton<String>(
            value: globalDefaultSourceId,
            hint: const Text('Select default source'),
            isExpanded: true,
            items: sources.map((s) => DropdownMenuItem(
              value: s.id?.toString(),
              child: Text(s.name ?? 'Unknown'),
            )).toList(),
            onChanged: saveGlobalDefaultSource,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Manage Source Domains', style: TextStyle(fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Source'),
                onPressed: showAddSourceDialog,
              ),
            ],
          ),
          ...sources.map((source) => _SourceDomainEditor(
            source: source,
            onDomainsChanged: (domains) => saveDomains(source, domains),
          )),
        ],
      ),
    );
  }
}

class _SourceDomainEditor extends StatefulWidget {
  final Source source;
  final ValueChanged<List<String>> onDomainsChanged;
  const _SourceDomainEditor({required this.source, required this.onDomainsChanged, Key? key}) : super(key: key);

  @override
  State<_SourceDomainEditor> createState() => _SourceDomainEditorState();
}

class _SourceDomainEditorState extends State<_SourceDomainEditor> {
  late List<String> domains;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    domains = List<String>.from(widget.source.baseUrls ?? (widget.source.baseUrl != null ? [widget.source.baseUrl!] : []));
  }

  void addDomain() {
    final text = _controller.text.trim();
    if (text.isNotEmpty && !domains.contains(text)) {
      setState(() {
        domains.add(text);
        _controller.clear();
        widget.onDomainsChanged(domains);
      });
    }
  }

  void removeDomain(int index) {
    setState(() {
      domains.removeAt(index);
      widget.onDomainsChanged(domains);
    });
  }

  void reorderDomains(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = domains.removeAt(oldIndex);
      domains.insert(newIndex, item);
      widget.onDomainsChanged(domains);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: ExpansionTile(
        title: Text(widget.source.name ?? 'Unknown'),
        subtitle: const Text('Domains (try in order)'),
        children: [
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            onReorder: reorderDomains,
            children: [
              for (int i = 0; i < domains.length; i++)
                ListTile(
                  key: ValueKey(domains[i]),
                  title: Text(domains[i]),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => removeDomain(i),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: 'Add new domain'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: addDomain,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
