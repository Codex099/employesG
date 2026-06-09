import 'package:flutter/material.dart';

class Translations {
  static const Map<String, Map<String, String>> _dict = {
    // ── Common & General ──
    'app_title': {
      'ar': 'GeEm',
      'fr': 'GeEm'
    },
    'cancel': {
      'ar': 'إلغاء',
      'fr': 'Annuler'
    },
    'save': {
      'ar': 'حفظ',
      'fr': 'Enregistrer'
    },
    'delete': {
      'ar': 'حذف',
      'fr': 'Supprimer'
    },
    'edit': {
      'ar': 'تعديل',
      'fr': 'Modifier'
    },
    'yes': {
      'ar': 'نعم',
      'fr': 'Oui'
    },
    'no': {
      'ar': 'لا',
      'fr': 'Non'
    },
    'required': {
      'ar': 'مطلوب',
      'fr': 'Requis'
    },
    'unknown': {
      'ar': 'غير معروف',
      'fr': 'Inconnu'
    },
    'you': {
      'ar': 'أنت',
      'fr': 'Vous'
    },
    'select': {
      'ar': 'اختر',
      'fr': 'Sélectionner'
    },
    
    // ── Splash Screen ──
    'egm_group': {
      'ar': 'EGM GROUP',
      'fr': 'EGM GROUP'
    },
    'labor_management': {
      'ar': 'إدارة العمال',
      'fr': 'Gestion des employés'
    },
    'labor_system': {
      'ar': 'نظام متابعة القوى العاملة',
      'fr': 'Système de suivi de la main-d\'œuvre'
    },

    // ── Login Screen ──
    'login_title': {
      'ar': 'تسجيل الدخول للمتابعة',
      'fr': 'Connexion pour continuer'
    },
    'username': {
      'ar': 'اسم المستخدم',
      'fr': 'Nom d\'utilisateur'
    },
    'username_hint': {
      'ar': 'أدخل اسم المستخدم',
      'fr': 'Entrez le nom d\'utilisateur'
    },
    'password': {
      'ar': 'كلمة المرور',
      'fr': 'Mot de passe'
    },
    'password_hint': {
      'ar': 'أدخل كلمة المرور',
      'fr': 'Entrez le mot de passe'
    },
    'login_btn': {
      'ar': 'دخول',
      'fr': 'Se connecter'
    },

    // ── Sidebar & Menu ──
    'home_menu': {
      'ar': 'الرئيسية',
      'fr': 'Accueil'
    },
    'add_employee': {
      'ar': 'إضافة عامل',
      'fr': 'Ajouter un employé'
    },
    'absences_menu': {
      'ar': 'الغيابات',
      'fr': 'Absences'
    },
    'archive_menu': {
      'ar': 'الأرشيف',
      'fr': 'Archives'
    },
    'user_management': {
      'ar': 'إدارة المستخدمين',
      'fr': 'Gestion des utilisateurs'
    },
    'logout': {
      'ar': 'تسجيل الخروج',
      'fr': 'Se déconnecter'
    },
    'language': {
      'ar': 'اللغة / Langue',
      'fr': 'Langue / اللغة'
    },
    'workplaces_menu': {
      'ar': 'أماكن العمل',
      'fr': 'Lieux de travail'
    },
    'add_workplace': {
      'ar': 'إضافة مكان عمل',
      'fr': 'Ajouter un lieu'
    },
    'workplace_name_hint': {
      'ar': 'اسم مكان العمل...',
      'fr': 'Nom du lieu...'
    },
    'empty_workplaces': {
      'ar': 'لا توجد أماكن عمل مسجلة',
      'fr': 'Aucun lieu enregistré'
    },
    'import_success': {
      'ar': 'تم استيراد البيانات بنجاح',
      'fr': 'Données importées avec succès'
    },
    'export_success': {
      'ar': 'تم تصدير البيانات بنجاح',
      'fr': 'Données exportées avec succès'
    },
    'file_error': {
      'ar': 'خطأ في معالجة الملف',
      'fr': 'Erreur de traitement du fichier'
    },

    // ── Home Screen ──
    'search_hint': {
      'ar': 'ابحث بالاسم أو رقم التسجيل...',
      'fr': 'Rechercher par nom ou MAT...'
    },
    'no_match': {
      'ar': 'لا يوجد عمال مطابقين',
      'fr': 'Aucun employé correspondant'
    },
    'confirm_delete': {
      'ar': 'هل أنت متأكد من حذف',
      'fr': 'Êtes-vous sûr de vouloir supprimer'
    },
    'personal_info': {
      'ar': 'المعلومات الشخصية',
      'fr': 'Informations personnelles'
    },
    'children_count': {
      'ar': 'الأولاد',
      'fr': 'Enfants'
    },
    'blood_type': {
      'ar': 'فصيلة الدم',
      'fr': 'Groupe sanguin'
    },
    'observations': {
      'ar': 'الملاحظات',
      'fr': 'Observations'
    },
    'current_absence_details': {
      'ar': 'تفاصيل الغياب الحالي',
      'fr': 'Détails de l\'absence actuelle'
    },
    'absence_date': {
      'ar': 'تاريخ تسجيل الغياب',
      'fr': 'Date d\'enregistrement'
    },
    'confirm_logout': {
      'ar': 'هل تريد الخروج؟',
      'fr': 'Voulez-vous vous déconnecter ?'
    },
    'syncing': {
      'ar': 'جارِ المزامنة...',
      'fr': 'Synchronisation en cours...'
    },
    'last_sync': {
      'ar': 'آخر مزامنة',
      'fr': 'Dernière sync'
    },

    // ── Employee Card ──
    'call_phone': {
      'ar': 'اتصال الهاتف',
      'fr': 'Appel vocal'
    },
    'call_whatsapp': {
      'ar': 'واتساب',
      'fr': 'WhatsApp'
    },

    // ── Stats Bar ──
    'total_count': {
      'ar': 'إجمالي',
      'fr': 'Total'
    },
    'status_married': {
      'ar': 'متزوج',
      'fr': 'Marié'
    },
    'status_single': {
      'ar': 'أعزب',
      'fr': 'Célibataire'
    },
    'status_widowed': {
      'ar': 'أرمل',
      'fr': 'Veuf(ve)'
    },

    // ── Forms (Employee addedit) ──
    'new_employee': {
      'ar': 'إضافة عامل جديد',
      'fr': 'Ajouter un nouvel employé'
    },
    'edit_employee': {
      'ar': 'تعديل بيانات العامل',
      'fr': 'Modifier l\'employé'
    },
    'full_name': {
      'ar': 'الاسم واللقب',
      'fr': 'Nom et prénom'
    },
    'reg_number': {
      'ar': 'رقم التسجيل (MAT)',
      'fr': 'Matricule (MAT)'
    },
    'phone_number': {
      'ar': 'رقم الهاتف',
      'fr': 'Numéro de téléphone'
    },
    'address': {
      'ar': 'العنوان / المنطقة',
      'fr': 'Adresse / Région'
    },
    'workplace': {
      'ar': 'مكان العمل / المشروع',
      'fr': 'Lieu de travail / Chantier'
    },
    'family_status': {
      'ar': 'الحالة العائلية',
      'fr': 'Situation familiale'
    },

    // ── Absences ──
    'absences_list': {
      'ar': 'قائمة الغيابات',
      'fr': 'Liste des absences'
    },
    'search_absence_hint': {
      'ar': 'ابحث بالاسم، رقم التسجيل، أو نوع الغياب...',
      'fr': 'Recherche par nom, MAT, ou type d\'absence...'
    },
    'no_absences': {
      'ar': 'لا توجد غيابات مسجلة',
      'fr': 'Aucune absence enregistrée'
    },
    'absence_records': {
      'ar': 'سجل',
      'fr': 'enregistrement(s)'
    },
    'absence_type': {
      'ar': 'نوع الغياب',
      'fr': 'Type d\'absence'
    },
    'absence_days': {
      'ar': 'عدد الأيام',
      'fr': 'Nb de jours'
    },
    'start_date': {
      'ar': 'تاريخ البدء',
      'fr': 'Date de début'
    },
    'return_date': {
      'ar': 'تاريخ الالتحاق',
      'fr': 'Date de retour'
    },
    'absence_reason': {
      'ar': 'السبب أو ملاحظة (اختياري)...',
      'fr': 'Raison ou observation (optionnel)...'
    },
    'register_absence': {
      'ar': 'تسجيل الغياب',
      'fr': 'Enregistrer l\'absence'
    },
    'register_employee_absence': {
      'ar': 'تسجيل غياب الموظف',
      'fr': 'Enregistrer l\'absence'
    },
    'absence_unauthorized': {
      'ar': 'غياب بدون إذن — سيسجل فوراً',
      'fr': 'Absence non autorisée — enregistrée immédiatement'
    },
    'absence_archive': {
      'ar': 'أرشيف الغيابات',
      'fr': 'Archive des absences'
    },
    'search_archive_hint': {
      'ar': 'ابحث بالاسم أو نوع الغياب...',
      'fr': 'Recherche par nom ou type d\'absence...'
    },
    'empty_archive': {
      'ar': 'الأرشيف فارغ',
      'fr': 'Les archives sont vides'
    },
    'end_absence': {
      'ar': 'إنهاء الغياب',
      'fr': 'Terminer l\'absence'
    },
    'select_all': {
      'ar': 'تحديد الكل',
      'fr': 'Tout sélectionner'
    },
    'archive_selected': {
      'ar': 'أرشفة المحدد',
      'fr': 'Archiver la sélection'
    },
    'delete_selected': {
      'ar': 'حذف المحدد',
      'fr': 'Supprimer la sélection'
    },
    'archive_confirm': {
      'ar': 'هل تريد أرشفة غياب',
      'fr': 'Voulez-vous archiver l\'absence de'
    },
    'archive_all': {
      'ar': 'أرشفة الكل',
      'fr': 'Archiver tout'
    },
    'archived_success': {
      'ar': 'تمت أرشفة الغيابات المحددة',
      'fr': 'Absences sélectionnées archivées'
    },
    'delete_confirm': {
      'ar': 'هل تريد حذف غياب',
      'fr': 'Voulez-vous supprimer l\'absence de'
    },
    'delete_all': {
      'ar': 'حذف الكل',
      'fr': 'Supprimer tout'
    },
    'deleted_success': {
      'ar': 'تم حذف الغيابات المحددة',
      'fr': 'Absences sélectionnées supprimées'
    },
    'selected_count': {
      'ar': 'تم تحديد',
      'fr': 'Sélectionné'
    },


    // ── Users Management ──
    'new_user': {
      'ar': 'إضافة مستخدم جديد',
      'fr': 'Ajouter un nouvel utilisateur'
    },
    'edit_user': {
      'ar': 'تعديل المستخدم',
      'fr': 'Modifier l\'utilisateur'
    },
    'password_empty_keep': {
      'ar': 'كلمة المرور الجديدة (اتركها فارغة للإبقاء)',
      'fr': 'Nouveau mot de passe (laisser vide pour garder)'
    },
    'role': {
      'ar': 'الصلاحية',
      'fr': 'Rôle'
    },
    'no_users': {
      'ar': 'لا يوجد مستخدمون',
      'fr': 'Aucun utilisateur'
    },
    'manager': {
      'ar': 'المدير',
      'fr': 'Directeur'
    },

    // ── Feedback messages ──
    'saved_successfully': {
      'ar': 'تم الحفظ بنجاح',
      'fr': 'Enregistré avec succès'
    },
    'error_occurred': {
      'ar': 'حدث خطأ',
      'fr': 'Une erreur est survenue'
    },
    'deleted_successfully': {
      'ar': 'تم الحذف',
      'fr': 'Supprimé'
    },
    'invalid_credentials': {
      'ar': 'اسم المستخدم أو كلمة المرور غير صحيحة',
      'fr': 'Nom d\'utilisateur ou mot de passe incorrect'
    },
    'connection_error': {
      'ar': 'خطأ في الاتصال، تحقق من الإنترنت',
      'fr': 'Erreur de connexion, vérifiez internet'
    },
    'manual_mode': {
      'ar': 'وضع يدوي',
      'fr': 'Mode manuel'
    },
    'online': {
      'ar': 'متصل',
      'fr': 'En ligne'
    },
    'offline': {
      'ar': 'غير متصل',
      'fr': 'Hors ligne'
    },
    'settings': {
      'ar': 'الإعدادات',
      'fr': 'Paramètres'
    },
    'light_mode': {
      'ar': 'الوضع النهاري',
      'fr': 'Mode clair'
    },
    'dark_mode': {
      'ar': 'الوضع الليلي',
      'fr': 'Mode sombre'
    },
    'export_data': {
      'ar': 'تصدير البيانات',
      'fr': 'Exporter les données'
    },
    'import_data': {
      'ar': 'استيراد البيانات',
      'fr': 'Importer les données'
    },
    'call_direct': {
      'ar': 'اتصال مباشر',
      'fr': 'Appel direct'
    },
    'whatsapp': {
      'ar': 'واتساب',
      'fr': 'WhatsApp'
    },
    'register_absence_btn': {
      'ar': 'تسجيل غياب الموظف',
      'fr': 'Enregistrer l\'absence'
    },
    'absence_history': {
      'ar': 'سجل غيابات',
      'fr': 'Historique des absences'
    },
    'absences_count': {
      'ar': 'غياب مسجل',
      'fr': 'Absence(s) enregistrée(s)'
    },
    'no_absence_history': {
      'ar': 'لا يوجد سجل غيابات',
      'fr': 'Aucun historique d\'absences'
    },
    'current': {
      'ar': 'حالي',
      'fr': 'Actuel'
    },
    'sick_leave': {
      'ar': 'نقاهة',
      'fr': 'Maladie'
    },
    'unauthorized_absence': {
      'ar': 'غ غ ش',
      'fr': 'A M'
    },
    'vacation': {
      'ar': 'إجازة',
      'fr': 'Congé'
    },
    'absence_permission': {
      'ar': 'رخصة غياب',
      'fr': 'Permission'
    },
    'days_count': {
      'ar': 'عدد الأيام',
      'fr': 'Nombre de jours'
    },
    'start_date_absence': {
      'ar': 'تاريخ البدء',
      'fr': 'Date de début'
    },
    'unauthorized_warning': {
      'ar': 'غياب بدون إذن — سيسجل فوراً',
      'fr': 'Absence non autorisée — enregistrée immédiatement'
    },
    'reason_hint': {
      'ar': 'السبب أو ملاحظة (اختياري)...',
      'fr': 'Raison ou note (optionnel)...'
    },
    'submit_absence': {
      'ar': 'تسجيل الغياب',
      'fr': 'Valider l\'absence'
    },
    'from': {
      'ar': 'من',
      'fr': 'Du'
    }
  };

  static String get(String key, String locale) {
    if (_dict.containsKey(key)) {
      return _dict[key]![locale] ?? key;
    }
    return key;
  }
}

extension StringTr on String {
  String tr(BuildContext context) {
    if (this.isEmpty) return '';
    try {
      final locale = Localizations.localeOf(context).languageCode;
      return Translations.get(this, locale);
    } catch (e) {
      // Fallback
      return Translations.get(this, 'ar');
    }
  }
}
