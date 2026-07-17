import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/pengingat_model.dart';
import '../services/pengingat_service.dart';
import '../theme/app_theme.dart';
import 'pengingat_detail_screen.dart';

class PengingatListScreen extends StatelessWidget {
  const PengingatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = PengingatService();

    return Scaffold(
      backgroundColor: context.vx.background,
      appBar: AppBar(
        backgroundColor: context.vx.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Pengingat Obat',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: context.vx.textDark,
          ),
        ),
      ),
      body: StreamBuilder<List<PengingatModel>>(
        stream: service.streamPengingatAktif(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: context.vx.primary),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Gagal memuat data pengingat.',
                style: GoogleFonts.poppins(
                    fontSize: 14, color: context.vx.textMedium),
              ),
            );
          }

          final list = snapshot.data ?? [];

          if (list.isEmpty) {
            return const _EmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final p = list[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PengingatCard(pengingat: p),
              );
            },
          );
        },
      ),
    );
  }
}

// ─── Empty State ─────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: context.vx.chipTeal,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.notifications_off_outlined,
                  color: context.vx.primary, size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              'Belum ada pengingat obat',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: context.vx.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pengingat akan muncul di sini setelah kamu\nmendapat rekomendasi obat dari cek gejala.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: context.vx.textMedium,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Card Pengingat ───────────────────────────────────────────────────────
class _PengingatCard extends StatelessWidget {
  final PengingatModel pengingat;
  const _PengingatCard({required this.pengingat});

  @override
  Widget build(BuildContext context) {
    final berikutnya = pengingat.jadwalBerikutnya;
    final labelJadwal = berikutnya != null
        ? 'Berikutnya pukul $berikutnya'
        : 'Selesai untuk hari ini';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PengingatDetailScreen(
              pengingatId: pengingat.id,
              namaObat: pengingat.namaObat,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.vx.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.vx.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: context.vx.chipTeal,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.medication_rounded,
                  color: context.vx.primary, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          pengingat.namaObat,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: context.vx.textDark,
                          ),
                        ),
                      ),
                      if (pengingat.sudah3Hari) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.warning_amber_rounded,
                            color: Colors.orange.shade600, size: 15),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    labelJadwal,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: context.vx.textMedium,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: context.vx.chipTeal,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Hari ke-${pengingat.hariPenggunaanDihitung}',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: context.vx.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: context.vx.textLight, size: 22),
          ],
        ),
      ),
    );
  }
}