# KILLUA UNLOCK V2

## Déploiement Android + Vercel
1. Décompresse le ZIP et téléverse tous les fichiers ainsi que le dossier `supabase` dans un dépôt GitHub.
2. Dans Vercel, importe le dépôt, choisis le preset `Other`, sans commande de build.
3. Crée un projet sur https://supabase.com. Dans SQL Editor, exécute tout `supabase/schema.sql`.
4. Dans Supabase > Project Settings > API, copie l'URL du projet et la clé publique `anon`/publishable. Remplace `url` et `anonKey` au début de `app.js` par ces valeurs. Ne colle JAMAIS la clé `service_role` dans le navigateur.
5. Redéploie Vercel. Dans Supabase Authentication, règle les URL du site et les redirections sur ton domaine Vercel.
6. Crée ton compte sur le site. Puis, dans SQL Editor, attribue le rôle admin à ton email : `update public.profiles set role='admin' where email='TON_EMAIL';`
7. Reconnecte-toi. L'espace admin permet d'approuver ou refuser les demandes. Avant d'approuver, vérifie le transfert dans le compte opérateur, pas uniquement le texte fourni par le client.

## Numéro fourni
Le site affiche `+233 991 234 418`. L'indicatif +233 correspond au Ghana, pas à la RDC. Confirme le pays, le bénéficiaire, l'opérateur et que ce numéro reçoit bien le service Mobile Money annoncé avant de demander un paiement. Le site ne déclenche aucun transfert.

## Ce que fait cette version
- Inscription/connexion via Supabase Auth
- Demandes de forfait 7/14/30 jours
- Référence de transaction, statut en attente, actif ou refusé
- Espace admin basé sur un rôle accordé en base
- Approbation via fonction SQL qui fixe une expiration
Le paiement est vérifié manuellement, pas automatiquement. Les prix sont des exemples en USD.

## Limites et sécurité
Cette version est un portail d'abonnements pour des services autorisés de diagnostic/réparation. Elle ne débloque pas automatiquement un appareil USB et ne contourne pas iCloud, les codes d'accès ou les protections antivol. Ajoute avant lancement public les conditions d'utilisation, la politique de confidentialité et un contact de support. La clé publique Supabase est conçue pour être exposée avec RLS; ne mets jamais une clé secrète/service_role dans `app.js`.
