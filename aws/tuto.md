
# 🌩️ Tutoriel EC2 – Cloud Lab (Semaine 1)

> Objectif : Lancer une instance EC2 Ubuntu, y installer NGINX, créer une AMI custom, et comprendre les bases de la sécurité réseau AWS.

---

## 🛠️ Prérequis

- Compte AWS actif (Free Tier)
- AWS CLI installé et configuré (`aws configure`)
- Terminal disponible (PowerShell, Git Bash, ou WSL sous Windows)

---

## 1. 🔐 Création d’un utilisateur IAM

- Console IAM → Add user
- Nom : `cloud-lab-user`
- Type : `Programmatic access`
- Permissions : `AdministratorAccess` (temporairement)
- Télécharger le fichier `.csv` contenant Access Key + Secret

---

## 2. ⚙️ Configuration de l’AWS CLI

```bash
aws configure
```

Réponses :
- AWS Access Key ID → [copié depuis CSV]
- AWS Secret Access Key → [copié depuis CSV]
- Region → `eu-west-3` (Paris)
- Output format → `json`

Test :
```bash
aws sts get-caller-identity
```

---

## 3. 🚀 Lancer une instance EC2 Ubuntu

1. Console EC2 → Launch Instance
2. Nom : `cloud-lab-ubuntu`
3. AMI : `Ubuntu Server 22.04 LTS`
4. Type : `t2.micro` (Free Tier)
5. Key Pair : créer `cloudlab-key.pem` et la télécharger
6. Security Group :
   - SSH : TCP 22, source = Anywhere
   - HTTP : TCP 80, source = Anywhere
7. Launch !

---

## 4. 🔗 Connexion SSH

Sous PowerShell ou Bash :

```bash
ssh -i cloudlab-key.pem ubuntu@<public-ip>
```

⚠️ Assure-toi que le fichier `.pem` est sécurisé :
```bash
chmod 400 cloudlab-key.pem   # ou équivalent PowerShell
```

---

## 5. 🌐 Installer et tester NGINX

```bash
sudo apt update && sudo apt install nginx -y
sudo systemctl start nginx
sudo systemctl enable nginx
```

Accède à ton instance via navigateur :  
```
http://<public-ip>
```

Tu dois voir la page "Welcome to nginx!".

---

## 6. 📸 Créer une AMI custom

1. Console EC2 → Instances
2. Coche ton instance
3. Actions → Image and templates → Create Image
4. Nom : `cloud-lab-nginx-image`
5. Laisser les options par défaut → Create Image

L’AMI apparaîtra dans EC2 > **AMIs**

---

## 7. 🔐 Comprendre la sécurité AWS

### ✅ Key Pair
- Sert à s’authentifier en SSH
- Jamais la perdre, jamais la versionner

### ✅ Security Group
- Pare-feu virtuel autour de l’instance
- Par défaut : tout bloqué
- Ici, on a autorisé :
  - SSH (port 22)
  - HTTP (port 80)

---

## ✅ Prochaine étape (Semaine 2)

→ Créer un bucket S3  
→ Héberger un site statique simple  
→ Explorer CloudFront, SSL, et presigned URLs

---

## 🧠 À noter

- EC2 = VM cloud managée par AWS
- AMI = snapshot réutilisable
- NGINX = serveur web + reverse proxy léger
- Tout est reproductible en CLI, voire Terraform (plus tard)

---

📁 Dossier à commiter :
```
cloud-lab/
└── aws/
    └── ec2/
        ├── README.md
        ├── tutoriel-ec2.md
        └── captures/ (screenshots floutés optionnels)
```

```

---