RML ERP — V0.2
===============

Objectif
--------
Premier module réellement utilisable du futur ERP, construit totalement à côté des applications RML actuelles.

Fonctions V0.2
--------------
- Tableau de bord ERP
- Gestion des clients
- Création / modification / archivage des clients
- Gestion des chantiers rattachés à un client
- Recherche et filtrage
- Statuts chantier : actif, attente, terminé, archivé
- Dates, adresse, contact, responsable / chef d'équipe, notes
- Stockage LOCAL uniquement pour les essais
- Schéma Supabase DEV préparé mais non connecté

Sécurité
--------
Cette version ne lit, ne modifie et ne synchronise aucune donnée des applications RML actuellement en production.
Le fichier supabase-schema.sql doit être utilisé uniquement dans un NOUVEAU projet Supabase de développement.

Étape suivante prévue
---------------------
V0.3 : fiche chantier centrale avec accès aux futurs modules et mise en place de la synchronisation Supabase DEV après création du projet de test séparé.
