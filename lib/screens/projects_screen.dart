import 'package:flutter/material.dart';
import '../core/theme_controller.dart';
import '../data/project_repository.dart';
import '../models/project.dart';
import 'dimensions_screen.dart';
import 'style_guide_screen.dart';
import 'frame_screen.dart';
import 'help_screen.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});
  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  List<Project> _projects = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final list = await ProjectRepository.instance.getAll();
    if (!mounted) return;
    setState(() { _projects = list; _loading = false; });
  }

  Future<void> _delete(Project p) async {
    if (p.id == null) return;
    await ProjectRepository.instance.delete(p.id!);
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Проект «${p.name}» удалён'),
        action: SnackBarAction(
          label: 'Отменить',
          onPressed: () async {
            await ProjectRepository.instance.insert(p);
            _load();
          },
        ),
        duration: const Duration(seconds: 4),
      ),
    );
    
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('KARKAS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 4, color: Theme.of(context).colorScheme.primary)),
            const SizedBox(height: 4),
            const Text('Мои дома', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            tooltip: isDark ? 'Светлая тема' : 'Тёмная тема',
            onPressed: () => ThemeController.instance.toggle(),
          ),
          IconButton(
            icon: const Icon(Icons.auto_awesome_outlined),
            tooltip: 'Типажи',
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const StyleGuideScreen()));
              _load();
            },
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Справка',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpScreen())),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _loading 
          ? const Center(child: CircularProgressIndicator())
          : _projects.isEmpty
            ? _emptyState()
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _projects.length,
                itemBuilder: (_, i) {
                  final p = _projects[i];
                  return Dismissible(
                    key: ValueKey(p.id),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (_) async { 
                      await _delete(p); 
                      return false;
                    },
                    background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 24), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.delete_outline, color: Colors.white)),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(width: 48, height: 48, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.home_outlined, color: Theme.of(context).colorScheme.primary)),
                        
                        title: Text(
                          p.name, 
                          maxLines: 1, 
                          overflow: TextOverflow.ellipsis, 
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)
                        ),
                        
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('${p.dimensions.lengthM.toInt()} × ${p.dimensions.widthM.toInt()} м', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
                        ),
                        
                        trailing: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
                        onTap: () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (_) => FrameScreen(dimensions: p.dimensions, initialParams: p.frameParams, projectId: p.id, projectName: p.name, savedPrices: p.prices)));
                          _load();
                        },
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const DimensionsScreen()));
          _load();
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Новый дом'),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 96, height: 96, decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(28)), child: Icon(Icons.cabin_outlined, size: 44, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3))),
            const SizedBox(height: 24),
            const Text('Пока нет проектов', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Создайте первый дом — задайте размеры, выберите каркас и получите смету.', textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), height: 1.4)),
            const SizedBox(height: 32),
            FilledButton.icon(onPressed: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const DimensionsScreen())); _load(); }, icon: const Icon(Icons.add), label: const Text('Создать дом')),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const StyleGuideScreen())); _load(); },
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text('Выбрать типаж дома'),
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
            ),
          ],
        ),
      ),
    );
  }
}
