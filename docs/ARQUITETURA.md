# Documentação da Arquitetura

## Visão Geral

Este documento detalha a arquitetura técnica do **AWS Cloud Support Lab**.

## Diagrama Lógico

```
┌─────────────────────────────────────────────────┐
│            AWS Cloud Support Lab                │
│         VPC 10.0.0.0/16                         │
│                                                 │
│  ┌─────────────────────────────────────────┐   │
│  │  Public Subnet 10.0.1.0/24 (AZ-a)      │   │
│  │                                         │   │
│  │  ┌─────────────────┐                   │   │
│  │  │  Web Server     │                   │   │
│  │  │  EC2 t3.micro   │ ◄─── SSH (22)     │   │
│  │  │  Apache/HTTP    │ ◄─── HTTP (80)    │   │
│  │  │  HTTPS (443)    │                   │   │
│  │  └────────┬────────┘                   │   │
│  │           │                            │   │
│  └─────────────────────────────────────────┘   │
│           │                                    │
│           │ MySQL (3306) ◄─ SG Allow        │
│           │                                    │
│  ┌─────────▼─────────────────────────────┐   │
│  │  Private Subnet 10.0.2.0/24 (AZ-a)   │   │
│  │                                       │   │
│  │  ┌──────────────────┐                │   │
│  │  │  DB Server       │                │   │
│  │  │  EC2 t3.micro    │ ◄─ NO SSH      │   │
│  │  │  MySQL (3306)    │ ◄─ Web only    │   │
│  │  │  No IGW route    │                │   │
│  │  └──────────────────┘                │   │
│  │                                       │   │
│  └───────────────────────────────────────┘   │
│           │                                    │
│           └──────► S3 Bucket                 │
│                   (Backups + Logs)           │
│                                              │
│   IAM Role: EC2-CloudSupport-Role (Both)    │
│   Policies: S3 access                       │
│                                              │
└─────────────────────────────────────────────────┘
```

## Componentes em Detalhe

### VPC (Virtual Private Cloud)
- **CIDR:** 10.0.0.0/16
- **DNS:** Habilitado
- **Subnets:** 2 (1 pública, 1 privada)

### Subnets

#### Public Subnet
- **CIDR:** 10.0.1.0/24
- **AZ:** us-east-1a
- **Auto-assign Public IP:** Sim
- **Route Table:** Routes para IGW (0.0.0.0/0 -> IGW)

#### Private Subnet
- **CIDR:** 10.0.2.0/24
- **AZ:** us-east-1a
- **Auto-assign Public IP:** Não
- **Route Table:** SEM rota para internet (sem NAT Gateway)

### Internet Gateway (IGW)
- **Nome:** CloudSupport-IGW
- **Anexado à:** VPC CloudSupport
- **Função:** Permitir comunicação entre VPC e internet

### Security Groups

#### Web-SG (sg-web-*)
**Ingress Rules:**
- TCP 80 (HTTP): 0.0.0.0/0
- TCP 443 (HTTPS): 0.0.0.0/0
- NOTA: SSH (22) NÃO está aberto por padrão (incidente de troubleshooting)

**Egress Rules:**
- Tudo permitido (0.0.0.0/0)

#### DB-SG (sg-db-*)
**Ingress Rules:**
- TCP 3306 (MySQL): Somente de Web-SG
- NOTA: Sem acesso direto de internet

**Egress Rules:**
- Tudo permitido (0.0.0.0/0)

### EC2 Instances

#### Web Server
- **AMI:** Amazon Linux 2
- **Instance Type:** t3.micro
- **Subnet:** Public Subnet
- **Public IP:** Sim (auto-assign)
- **Security Group:** Web-SG
- **IAM Role:** EC2-CloudSupport-Role
- **User Data:** Instala Apache, inicia serviço

#### DB Server
- **AMI:** Amazon Linux 2
- **Instance Type:** t3.micro
- **Subnet:** Private Subnet
- **Public IP:** Não
- **Security Group:** DB-SG
- **IAM Role:** EC2-CloudSupport-Role
- **User Data:** Instala MySQL, inicia serviço

### S3 Bucket
- **Nome:** cloudsupport-lab-{AccountID}
- **Versionamento:** Habilitado
- **Bloqueio de IP Público:** Configurável
- **Uso:** Backups, logs, arquivos de configuração

### IAM Role: EC2-CloudSupport-Role
**Trust Policy:**
- Principal: ec2.amazonaws.com
- Action: sts:AssumeRole

**Attached Policies:**
- S3 Access Policy (GetObject, PutObject, ListBucket, DeleteObject)

## Fluxo de Comunicação

1. **Cliente → Web Server**
   - Internet → IGW → Public RT → Web-SG (HTTP/HTTPS)
   - EC2 responde com página HTML

2. **Web Server → DB Server**
   - Web-SG → Private Subnet → DB-SG (MySQL 3306)
   - Requer regra "source-group" no DB-SG

3. **Web Server → S3**
   - EC2 assume IAM Role → S3 API
   - Requer permissões na policy

4. **DB Server → S3** (opcional)
   - Mesma rota: IAM Role → S3 API

## Cenários de Troubleshooting

### Problema #1: SSH Fechado
**Causa:** Web-SG sem regra para porta 22
**Solução:** Adicionar regra ao Web-SG

### Problema #2: EC2 sem S3
**Causa:** IAM Role sem permissão S3
**Solução:** Adicionar policy com s3:GetObject, s3:PutObject

### Problema #3: Web → DB não conecta
**Causa:** DB-SG sem regra para Web-SG
**Solução:** Adicionar regra ingress (TCP 3306 from Web-SG)

## Limites Free Tier

- EC2: 750 horas/mês (2 x t3.micro = 730 horas)
- S3: 5 GB grátis
- Data Transfer: 1 GB/mês grátis
- CloudWatch: 10 métricas customizadas grátis

## Monitoramento (CloudWatch)

- **Logs:** `/aws/ec2/web-server` e `/aws/ec2/db-server`
- **Métricas:** CPU, Network In/Out, Disk
- **Alarms:** Opcionais (triggers para baixo)
