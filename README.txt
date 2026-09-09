RML ERP — V0.3
===============

Objectif
--------
Première version connectée au projet Supabase RML ERP DEV.

Fonctions V0.3
--------------
- Authentification Supabase par e-mail / mot de passe
- Session persistante sur l'appareil
- Déconnexion
- Lecture des clients depuis Supabase
- Création / modification / archivage des clients dans Supabase
- Lecture des chantiers depuis Supabase
- Création / modification des chantiers dans Supabase
- Synchronisation entre appareils connectés au même projet
- Indicateur d'état de synchronisation
- Première fiche chantier centrale avec accès aux futurs modules
- Aucun accès aux applications RML actuellement en production

Sécurité
--------
- La clé intégrée est une clé publique/publishable uniquement.
- Aucune clé service_role ou secrète n'est utilisée.
- Les tables sont protégées par RLS.
- Les policies V0.3 autorisent l'accès uniquement aux utilisateurs authentifiés.

Fichiers
--------
- index.html : application V0.3
- supabase-schema.sql : schéma initial V0.2
- rls-policies-v0.3.sql : policies déjà exécutées dans Supabase

Mise en ligne DEV
-----------------
Remplacer index.html dans le dépôt GitHub RML-ERP-DEV par cette version.
