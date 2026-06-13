# Guide d'installation de Tina

Suis ces étapes dans l'ordre. Ça prend environ 15 minutes au total.

---

## ÉTAPE 1 : Créer un compte GitHub (2 min)

1. Va sur **github.com**
2. Clique sur "Sign up"
3. Entre ton email, crée un mot de passe, choisis un nom d'utilisateur
4. Valide ton compte avec le code reçu par email

---

## ÉTAPE 2 : Créer le dépôt pour Tina (2 min)

1. Une fois connecté sur GitHub, clique sur le bouton vert **"New"** en haut à gauche
2. Dans "Repository name", écris : `tina-app`
3. Assure-toi que c'est en **Public**
4. Clique sur **"Create repository"**

---

## ÉTAPE 3 : Uploader les fichiers (5 min)

1. Sur la page du dépôt vide, clique sur **"uploading an existing file"**
2. Ouvre l'explorateur de fichiers Windows sur ton PC
3. Va dans : `C:\Users\RAQIIB\OneDrive\Desktop\jarvis\tina-app\`
4. Sélectionne **tous les fichiers et dossiers** (Ctrl+A)
5. Fais les glisser dans la fenêtre GitHub
6. En bas, écris un message : `Premier upload Tina`
7. Clique sur **"Commit changes"**

> Note : GitHub peut ne pas uploader les dossiers vides. Si tu as une erreur, recommence en sélectionnant fichier par fichier.

---

## ÉTAPE 4 : Créer ta clé API Groq (3 min)

1. Va sur **console.groq.com**
2. Clique sur "Sign up" et crée un compte gratuit
3. Une fois connecté, clique sur **"API Keys"** dans le menu à gauche
4. Clique sur **"Create API Key"**
5. Donne-lui un nom (ex: "Tina") et clique sur "Submit"
6. **COPIE la clé** qui apparaît (elle commence par `gsk_...`) et sauvegarde-la quelque part, elle ne s'affichera qu'une seule fois

---

## ÉTAPE 5 : Attendre la compilation (10 min)

1. Sur GitHub, clique sur l'onglet **"Actions"**
2. Tu veras un job "Build Tina APK" en train de tourner (cercle jaune)
3. Attends qu'il devienne vert (environ 8-10 minutes)
4. Si c'est rouge, dis-le à Tina (dans ce workspace) pour qu'elle corrige l'erreur

---

## ÉTAPE 6 : Télécharger l'APK

1. Une fois le job vert, clique dessus
2. Tout en bas de la page, dans la section **"Artifacts"**
3. Clique sur **"tina-app-release"** pour télécharger le fichier ZIP
4. Extrais le ZIP sur ton PC, tu obtiens `app-release.apk`

---

## ÉTAPE 7 : Installer Tina sur ton Pixel 4a

**Sur ton Pixel 4a :**

1. Va dans **Paramètres > Sécurité > Installer des apps inconnues**
2. Autorise ton navigateur ou gestionnaire de fichiers à installer des APK
3. Transfère le fichier `app-release.apk` sur ton téléphone (via câble USB, Google Drive, ou email à toi-même)
4. Ouvre le fichier APK depuis ton téléphone
5. Clique sur **"Installer"**
6. L'app **Tina** apparaît sur ton écran d'accueil

---

## ÉTAPE 8 : Configurer Tina

Au premier lancement :

1. L'app va te demander ta **clé API Groq** (celle que tu as copiée à l'étape 4)
2. Colle-la et appuie sur "Enregistrer"
3. Tina est maintenant active et te répond

---

## ÉTAPE 9 : Activer l'accès aux notifications

Pour que Tina voie tes messages WhatsApp, Facebook, Instagram :

1. Dans l'app, va dans l'onglet **"Notifs"** (dernière icône en bas)
2. Appuie sur **"Activer les notifications"**
3. Android ouvre les paramètres système
4. Dans la liste, trouve **"Tina"** et active le bouton
5. Reviens dans l'app et appuie sur "J'ai déjà activé, vérifier"

---

## C'est fini !

Tu as maintenant :
- Chat avec Tina (onglet 1)
- Générateur de scripts football (onglet 2)
- Matchs en direct et résultats via SofaScore (onglet 3)
- Toutes tes notifications centralisées (onglet 4)

---

## En cas de problème

Ouvre ce workspace Jarvis et dis à Tina exactement ce qui s'est passé.
