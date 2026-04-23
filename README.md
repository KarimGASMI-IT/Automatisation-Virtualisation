# Projet Ansible – Infrastructure web haute disponibilité avec monitoring

Ce dossier déploie automatiquement :
- **Apache2** sur `WEB1` (`10.1.1.21`) et `WEB2` (`10.1.1.22`)
- **HAProxy** sur `LB` (`10.1.1.20`)
- **Prometheus + Grafana** sur `MONITORING` (`10.1.1.30`)
- **Node Exporter** sur toutes les VM Linux gérées

Il est prévu pour ton réseau LAN pfSense :
- **pfSense LAN** : `10.1.1.1/24`
- **Passerelle par défaut des VM** : `10.1.1.1`
- **DNS conseillé** : `10.1.1.1`

---

## 1. Ce qu’il faut faire AVANT Ansible sur les VM

Fais ces actions manuellement avant de lancer le playbook.

### A. Créer les VM
- `10.1.1.20` → HAProxy
- `10.1.1.21` → Web1
- `10.1.1.22` → Web2
- `10.1.1.30` → Monitoring
- `NodeManager` → machine de contrôle Ansible

Toutes les VM Linux doivent être sur le **LAN VMware/pfSense**, pas sur le WAN.

### B. Configurer les IP fixes sur chaque VM Linux
Exemple :
- HAProxy → `10.1.1.20/24`
- Web1 → `10.1.1.21/24`
- Web2 → `10.1.1.22/24`
- Monitoring → `10.1.1.30/24`
- Passerelle → `10.1.1.1`
- DNS → `10.1.1.1`

### C. Installer le strict minimum sur chaque VM cible
Sur **chaque VM cible** (`10.1.1.20`, `.21`, `.22`, `.30`) :

```bash
sudo apt update
sudo apt install -y openssh-server sudo python3 python3-apt curl
sudo systemctl enable ssh
sudo systemctl start ssh
```

### D. Créer l’utilisateur `ansible` sur chaque VM cible

```bash
sudo adduser --shell /bin/bash --gecos "" ansible
sudo usermod -aG sudo ansible
sudo visudo
```

Ajoute cette ligne à la fin du fichier sudoers :

```text
ansible ALL=(ALL) NOPASSWD:ALL
```

### E. Installer Ansible sur NodeManager
Sur la machine **NodeManager** :

```bash
sudo apt update
sudo apt install -y ansible openssh-client sshpass
```

### F. Générer la clé SSH sur NodeManager
Fais-le avec **le même utilisateur** qui lancera Ansible, pas en root si tu travailles avec `user`.

```bash
ssh-keygen -t ed25519
```

### G. Copier la clé SSH vers chaque VM cible
Depuis NodeManager :

```bash
ssh-copy-id -i ~/.ssh/id_ed25519.pub ansible@10.1.1.20
ssh-copy-id -i ~/.ssh/id_ed25519.pub ansible@10.1.1.21
ssh-copy-id -i ~/.ssh/id_ed25519.pub ansible@10.1.1.22
ssh-copy-id -i ~/.ssh/id_ed25519.pub ansible@10.1.1.30
```

### H. Vérifier la connectivité SSH
Depuis NodeManager :

```bash
ssh ansible@10.1.1.20
ssh ansible@10.1.1.21
ssh ansible@10.1.1.22
ssh ansible@10.1.1.30
```

Chaque connexion doit fonctionner.

---

## 2. Installation du projet Ansible sur NodeManager

Copie ce dossier sur NodeManager, puis :

```bash
cd ~/projet_ansible_clean
ansible all -m ping
```

Résultat attendu : `pong` sur tous les hôtes.

---

## 3. Lancer l’installation complète

```bash
cd ~/projet_ansible_clean
ansible-playbook site.yml
```

Le playbook fait :
1. baseline système commune
2. node exporter sur toutes les VM Linux gérées
3. Apache sur Web1 et Web2
4. HAProxy sur `10.1.1.20`
5. Prometheus + Grafana sur `10.1.1.30`

---

## 4. Vérifications après installation

### A. Tester Apache directement
```bash
curl http://10.1.1.21
curl http://10.1.1.22
```

### B. Tester HAProxy
```bash
curl http://10.1.1.20
```
Tu dois voir une page provenant de Web1 ou Web2.

### C. Tester Prometheus
Navigateur :
```text
http://10.1.1.30:9090
```

### D. Tester Grafana
Navigateur :
```text
http://10.1.1.30:3000
```
Login initial Grafana :
- utilisateur : `admin`
- mot de passe : `admin`

---

## 5. Test de haute disponibilité

1. Ouvre `http://10.1.1.20`
2. Sur Web1, coupe Apache :
   ```bash
   sudo systemctl stop apache2
   ```
3. Recharge la page sur `10.1.1.20`
4. Le trafic doit continuer via Web2

---

## 6. Arborescence

```text
projet_ansible_clean/
├── ansible.cfg
├── group_vars/
│   └── all.yml
├── inventory.ini
├── README.md
├── site.yml
└── roles/
    ├── apache/
    ├── common/
    ├── grafana/
    ├── haproxy/
    ├── node_exporter/
    └── prometheus/
```

---

## 7. Commandes utiles

Tester l’inventaire :
```bash
ansible-inventory --list
```

Tester les hôtes :
```bash
ansible all -m ping
```

Relancer seulement HAProxy :
```bash
ansible-playbook site.yml --limit loadbalancer
```

Relancer seulement les webservers :
```bash
ansible-playbook site.yml --limit webservers
```

Relancer seulement le monitoring :
```bash
ansible-playbook site.yml --limit monitoring
```
