RML ERP DEV — V0.11.26 — ESPACE SALARIÉ — VERSION VÉRIFIÉE

Base : V0.11.25.

Fonctions :
- espace dédié Ouvrier / Chef d’équipe ;
- rattachement d’un compte ERP à un salarié RML Heures ;
- chantiers du jour et 30 jours à venir issus du Planning ERP ;
- feuille chantier avec client, adresse, contact et consignes ;
- documents explicitement partagés aux salariés ;
- ajout de plusieurs photos terrain ;
- Chef d’équipe : accès au Suivi chantier affecté ;
- garde-fous RLS restrictifs pour les comptes salariés.

Installation :
1. Remplacer index.html dans RML-ERP-DEV, Commit, Push.
2. Exécuter SQL_V0_11_26.sql uniquement dans Supabase RML ERP DEV.
3. Dans Utilisateurs & accès, rattacher un compte Ouvrier/Chef d’équipe à sa fiche RML Heures.
4. Affecter le salarié à un chantier dans Planning équipes.
5. Dans Documents, cocher la visibilité salariés sur les documents souhaités.

Ne modifie pas la base RML Heures ni les données Clients existantes.
