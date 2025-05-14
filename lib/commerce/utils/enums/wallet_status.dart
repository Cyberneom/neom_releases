enum WalletStatus {
  active,      // La billetera está completamente operativa.
  suspended,   // Suspendida temporalmente (ej. por actividad sospechosa, revisión administrativa).
  frozen,      // Los fondos no se pueden mover (ej. por requerimientos legales, verificación pendiente).
  closed,      // La billetera ha sido cerrada permanentemente.
}