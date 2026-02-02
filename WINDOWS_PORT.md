# Port para Windows - Roadmap

## Opções Tecnológicas

### 1. Tauri + Rust + Web (⭐ Recomendado)
**Pros:**
- App nativo leve (~5MB)
- Interface web (React/Vue)
- Acesso a APIs do sistema
- Seguro (Rust)

**Cons:**
- Reescrever UI
- Aprender Rust (básico)

**Tempo estimado:** 2-3 semanas

### 2. Flutter
**Pros:**
- Google, bem suportado
- UI bonita e consistente
- Hot reload

**Cons:**
- App maior (~50MB)
- Dart (nova linguagem)

**Tempo estimado:** 3-4 semanas

### 3. Electron
**Pros:**
- JavaScript/Node.js
- Muitos devs conhecem

**Cons:**
- App pesado (~150MB)
- Lento

**Tempo estimado:** 2 semanas

---

## Arquitetura Tauri (Recomendada)

```
Frontend (React/TypeScript)
    ↓
Tauri Bridge
    ↓
Rust Backend
    ↓
Windows APIs
```

### Features a implementar:
- [ ] Gravação de áudio (Windows Media Foundation)
- [ ] Global hotkeys (Windows RegisterHotKey)
- [ ] Clipboard access
- [ ] System tray
- [ ] Auto-startup

---

## Custo/Benefício

| Opção | Tempo | Tamanho | Qualidade |
|-------|-------|---------|-----------|
| Tauri | 2-3s | 5MB | ⭐⭐⭐⭐⭐ |
| Flutter | 3-4s | 50MB | ⭐⭐⭐⭐ |
| Electron | 2s | 150MB | ⭐⭐⭐ |

---

## Recomendação

**Tauri** - Melhor custo/benefício a longo prazo.

Quer que eu comece o protótipo?
