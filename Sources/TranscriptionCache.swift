import Foundation
import CryptoKit

/// Sistema de cache para transcrições de áudio
/// Evita chamadas repetidas à API para áudios idênticos
class TranscriptionCache {
    static let shared = TranscriptionCache()
    
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let metadataFile: URL
    private let maxCacheSizeMB = 50  // Limite máximo de 50MB
    private let maxCacheEntries = 100  // Máximo de entradas no cache
    
    /// Metadados de uma entrada de cache
    struct CacheEntry: Codable {
        let audioHash: String
        let transcription: String
        let timestamp: Date
        let audioSize: Int
        let tokenCount: Int  // Estimativa de tokens economizados
        let mode: String     // Modo de transcrição usado
        let language: String // Idioma de saída
    }
    
    private var entries: [String: CacheEntry] = [:]
    private let queue = DispatchQueue(label: "com.vibeflow.cache", qos: .utility)
    
    private init() {
        // Diretório de cache
        let cachesDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        cacheDirectory = cachesDir.appendingPathComponent("VibeFlow/Transcriptions", isDirectory: true)
        metadataFile = cacheDirectory.appendingPathComponent("metadata.json")
        
        // Criar diretório se não existir
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        // Carregar metadados
        loadMetadata()
        
        // Limpar entradas antigas
        cleanupOldEntries()
    }
    
    // MARK: - Operações de Cache
    
    /// Gera um hash único para os dados de áudio
    func hash(for audioData: Data) -> String {
        let hash = SHA256.hash(data: audioData)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    /// Busca uma transcrição em cache
    func get(audioData: Data, mode: TranscriptionMode, translateToEnglish: Bool) -> String? {
        let audioHash = hash(for: audioData)
        let cacheKey = makeCacheKey(audioHash: audioHash, mode: mode, translateToEnglish: translateToEnglish)
        
        return queue.sync {
            guard let entry = entries[cacheKey] else { return nil }
            
            // Verificar se o arquivo de áudio ainda existe
            let audioFile = cacheDirectory.appendingPathComponent("\(audioHash).m4a")
            guard fileManager.fileExists(atPath: audioFile.path) else {
                // Remover entrada inválida
                entries.removeValue(forKey: cacheKey)
                saveMetadata()
                return nil
            }
            
            // Atualizar timestamp (LRU)
            var updatedEntry = entry
            updatedEntry = CacheEntry(
                audioHash: entry.audioHash,
                transcription: entry.transcription,
                timestamp: Date(),
                audioSize: entry.audioSize,
                tokenCount: entry.tokenCount,
                mode: entry.mode,
                language: entry.language
            )
            entries[cacheKey] = updatedEntry
            saveMetadata()
            
            return entry.transcription
        }
    }
    
    /// Salva uma transcrição no cache
    func set(audioData: Data, transcription: String, mode: TranscriptionMode, translateToEnglish: Bool) {
        let audioHash = hash(for: audioData)
        let cacheKey = makeCacheKey(audioHash: audioHash, mode: mode, translateToEnglish: translateToEnglish)
        
        queue.async { [weak self] in
            guard let self = self else { return }
            
            // Verificar se devemos limpar o cache
            self.enforceCacheLimits()
            
            // Salvar arquivo de áudio
            let audioFile = self.cacheDirectory.appendingPathComponent("\(audioHash).m4a")
            if !self.fileManager.fileExists(atPath: audioFile.path) {
                try? audioData.write(to: audioFile)
            }
            
            // Criar entrada
            let entry = CacheEntry(
                audioHash: audioHash,
                transcription: transcription,
                timestamp: Date(),
                audioSize: audioData.count,
                tokenCount: self.estimateTokens(for: transcription),
                mode: mode.rawValue,
                language: translateToEnglish ? "en" : "pt"
            )
            
            self.entries[cacheKey] = entry
            self.saveMetadata()
        }
    }
    
    /// Verifica se uma transcrição está em cache
    func has(audioData: Data, mode: TranscriptionMode, translateToEnglish: Bool) -> Bool {
        let audioHash = hash(for: audioData)
        let cacheKey = makeCacheKey(audioHash: audioHash, mode: mode, translateToEnglish: translateToEnglish)
        
        return queue.sync {
            entries[cacheKey] != nil
        }
    }
    
    // MARK: - Detecção de Áudio Vazio/Ruído
    
    /// Verifica se o áudio é provavelmente silêncio ou ruído
    /// Retorna true se devemos evitar chamada à API
    func isProbablyEmpty(audioData: Data) -> Bool {
        // Verificar tamanho mínimo (menos de 1KB provavelmente é inválido)
        guard audioData.count > 1000 else { return true }
        
        // Verificar entropia do arquivo (arquivos de ruído têm entropia diferente)
        let entropy = calculateEntropy(audioData)
        
        // Entropia muito baixa = provavelmente silêncio comprimido
        // Entropia muito alta = provavelmente ruído puro
        if entropy < 2.0 || entropy > 7.5 {
            return true
        }
        
        return false
    }
    
    /// Calcula a entropia de Shannon dos dados
    private func calculateEntropy(_ data: Data) -> Double {
        var frequencies = [UInt8: Int]()
        
        for byte in data {
            frequencies[byte, default: 0] += 1
        }
        
        let length = Double(data.count)
        var entropy = 0.0
        
        for count in frequencies.values {
            let probability = Double(count) / length
            entropy -= probability * log2(probability)
        }
        
        return entropy
    }
    
    // MARK: - Estatísticas
    
    /// Estatísticas do cache
    var statistics: CacheStatistics {
        return queue.sync {
            let totalEntries = entries.count
            let totalSize = entries.values.reduce(0) { $0 + $1.audioSize }
            let totalTokensSaved = entries.values.reduce(0) { $0 + $1.tokenCount }
            
            // Encontrar entradas mais usadas (por timestamp recente)
            let sortedEntries = entries.values.sorted { $0.timestamp > $1.timestamp }
            let recentEntries = Array(sortedEntries.prefix(5))
            
            return CacheStatistics(
                totalEntries: totalEntries,
                totalSizeBytes: totalSize,
                totalTokensSaved: totalTokensSaved,
                recentEntries: recentEntries
            )
        }
    }
    
    /// Limpa todo o cache
    func clearCache() {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            // Remover arquivos
            try? self.fileManager.removeItem(at: self.cacheDirectory)
            try? self.fileManager.createDirectory(at: self.cacheDirectory, withIntermediateDirectories: true)
            
            // Limpar metadados
            self.entries.removeAll()
            self.saveMetadata()
        }
    }
    
    // MARK: - Helpers Privados
    
    private func makeCacheKey(audioHash: String, mode: TranscriptionMode, translateToEnglish: Bool) -> String {
        let langSuffix = translateToEnglish ? "_en" : "_pt"
        return "\(audioHash)_\(mode.rawValue)\(langSuffix)"
    }
    
    private func estimateTokens(for text: String) -> Int {
        // Estimativa aproximada: 1 token ~= 4 caracteres para inglês/português
        return max(1, text.count / 4)
    }
    
    private func loadMetadata() {
        guard let data = try? Data(contentsOf: metadataFile),
              let decoded = try? JSONDecoder().decode([String: CacheEntry].self, from: data) else {
            return
        }
        entries = decoded
    }
    
    private func saveMetadata() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: metadataFile)
    }
    
    private func cleanupOldEntries() {
        let cutoffDate = Date().addingTimeInterval(-7 * 24 * 60 * 60) // 7 dias
        
        entries = entries.filter { $0.value.timestamp > cutoffDate }
        saveMetadata()
    }
    
    private func enforceCacheLimits() {
        // Verificar número de entradas
        if entries.count > maxCacheEntries {
            // Remover entradas mais antigas
            let sorted = entries.sorted { $0.value.timestamp < $1.value.timestamp }
            let toRemove = sorted.prefix(entries.count - maxCacheEntries)
            
            for (key, _) in toRemove {
                entries.removeValue(forKey: key)
            }
        }
        
        // Verificar tamanho total
        let totalSize = entries.values.reduce(0) { $0 + $1.audioSize }
        let maxSizeBytes = maxCacheSizeMB * 1024 * 1024
        
        if totalSize > maxSizeBytes {
            // Remover entradas mais antigas até ficar abaixo do limite
            var sorted = entries.sorted { $0.value.timestamp < $1.value.timestamp }
            var currentSize = totalSize
            
            while currentSize > maxSizeBytes && !sorted.isEmpty {
                let (key, entry) = sorted.removeFirst()
                entries.removeValue(forKey: key)
                currentSize -= entry.audioSize
                
                // Também remover arquivo de áudio
                let audioFile = cacheDirectory.appendingPathComponent("\(entry.audioHash).m4a")
                try? fileManager.removeItem(at: audioFile)
            }
        }
    }
}

// MARK: - Estatísticas

struct CacheStatistics {
    let totalEntries: Int
    let totalSizeBytes: Int
    let totalTokensSaved: Int
    let recentEntries: [TranscriptionCache.CacheEntry]
    
    var totalSizeMB: Double {
        Double(totalSizeBytes) / (1024 * 1024)
    }
    
    var formattedSize: String {
        String(format: "%.2f MB", totalSizeMB)
    }
}
