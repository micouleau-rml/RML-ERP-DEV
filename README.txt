RML ERP DEV — V0.6

NOUVEAUTÉ PRINCIPALE
- Intégration réelle du module Préparation chantier dans l'ERP.
- Le module est ouvert depuis la fiche du chantier central.
- Les données sont enregistrées dans public.erp_modules_data avec module = preparation.
- Synchronisation entre appareils via le projet Supabase RML ERP DEV.
- Les droits V0.5 continuent de s'appliquer : sans permission preparation, le module est masqué et bloqué par RLS.
- L'application Préparation chantier actuellement en production n'est ni lue ni modifiée.

CONTENU REPRIS DU MODULE EXISTANT
- Gouttières
- Accessoires gouttières
- Descentes
- Accessoires descentes
- Couvertines
- Accessoires couvertines
- Bandeaux
- Sous-faces
- Couleurs, quantités, observations, remarques générales
- Impression / PDF A4

CATALOGUE AJOUTÉ
- CHAPEAU DE POTEAU
- RÉCUPÉRATEUR EP ROND
- RÉCUPÉRATEUR EP RECTANGLE

INSTALLATION
1. Aucun nouveau SQL à exécuter si la V0.5 fonctionne déjà.
2. Remplacer uniquement index.html dans le dépôt GitHub RML-ERP-DEV.
3. Commit conseillé : RML ERP V0.6 - Integration preparation chantier
4. Attendre la publication GitHub Pages puis actualiser la page.
5. Ouvrir un chantier > Préparation chantier > saisir une ligne > Enregistrer.
6. Vérifier sur un autre appareil que la préparation se recharge pour le même chantier.
