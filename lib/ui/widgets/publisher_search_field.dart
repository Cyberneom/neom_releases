import 'dart:async';

import 'package:flutter/material.dart';
import 'package:neom_commons/ui/theme/app_color.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/data/firestore/profile_firestore.dart';
import 'package:neom_core/domain/model/app_profile.dart';
import 'package:sint/sint.dart';

import '../../utils/constants/release_translation_constants.dart';

/// A search field that searches for publishers (users/profiles) with autocomplete.
/// Falls back to allowing free text input if no matches found.
class PublisherSearchField extends StatefulWidget {
  final TextEditingController controller;
  final Function(AppProfile?) onPublisherSelected;
  final String? initialValue;

  const PublisherSearchField({
    super.key,
    required this.controller,
    required this.onPublisherSelected,
    this.initialValue,
  });

  @override
  State<PublisherSearchField> createState() => _PublisherSearchFieldState();
}

class _PublisherSearchFieldState extends State<PublisherSearchField> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<AppProfile> _suggestions = [];
  bool _isLoading = false;
  Timer? _debounce;
  AppProfile? _selectedProfile;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _removeOverlay();
    widget.controller.removeListener(_onSearchChanged);
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _searchPublishers(widget.controller.text);
    });
  }

  Future<void> _searchPublishers(String query) async {
    if (query.trim().length < 2) {
      _removeOverlay();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final results = await ProfileFirestore().searchByName(query, limit: 10);

      if (mounted) {
        setState(() {
          _suggestions = results;
          _isLoading = false;
        });

        if (_suggestions.isNotEmpty || query.isNotEmpty) {
          _showSuggestions();
        }
      }
    } catch (e) {
      AppConfig.logger.e('Error searching publishers: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuggestions() {
    _removeOverlay();

    if (!mounted) return;

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 5),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(10),
            color: AppColor.getMain(),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 250),
              child: _buildSuggestionsList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionsList() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      children: [
        // Show matching profiles
        ..._suggestions.map((profile) => _buildSuggestionTile(profile)),

        // Always show "Use as custom text" option when there's input
        if (widget.controller.text.trim().isNotEmpty)
          _buildCustomTextTile(),
      ],
    );
  }

  Widget _buildSuggestionTile(AppProfile profile) {
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 18,
        backgroundImage: profile.photoUrl.isNotEmpty
            ? NetworkImage(profile.photoUrl)
            : null,
        child: profile.photoUrl.isEmpty
            ? Text(profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?')
            : null,
      ),
      title: Text(
        profile.name,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      ),
      subtitle: profile.aboutMe.isNotEmpty
          ? Text(
              profile.aboutMe,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      onTap: () => _selectProfile(profile),
    );
  }

  Widget _buildCustomTextTile() {
    return ListTile(
      dense: true,
      leading: const CircleAvatar(
        radius: 18,
        backgroundColor: Colors.grey,
        child: Icon(Icons.edit, size: 18, color: Colors.white),
      ),
      title: Text(
        '"${widget.controller.text.trim()}"',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        ReleaseTranslationConstants.useAsCustomPublisher.tr,
        style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
      ),
      onTap: () => _selectCustomText(),
    );
  }

  void _selectProfile(AppProfile profile) {
    setState(() {
      _selectedProfile = profile;
      widget.controller.text = profile.name;
    });
    _removeOverlay();
    widget.onPublisherSelected(profile);
    FocusScope.of(context).unfocus();
  }

  void _selectCustomText() {
    setState(() {
      _selectedProfile = null;
    });
    _removeOverlay();
    widget.onPublisherSelected(null);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: widget.controller,
        decoration: InputDecoration(
          filled: true,
          labelText: ReleaseTranslationConstants.specifyPublishingPlace.tr,
          labelStyle: const TextStyle(fontSize: 15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          suffixIcon: _selectedProfile != null
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    widget.controller.clear();
                    setState(() => _selectedProfile = null);
                    widget.onPublisherSelected(null);
                  },
                )
              : const Icon(Icons.search, size: 18),
        ),
        onTap: () {
          if (widget.controller.text.isNotEmpty) {
            _searchPublishers(widget.controller.text);
          }
        },
      ),
    );
  }
}
