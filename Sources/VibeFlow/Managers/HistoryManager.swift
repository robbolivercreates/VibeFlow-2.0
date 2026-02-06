import Foundation
import Combine
import AppKit

/// Representa um item no histórico de transcrições
struct HistoryItem: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let text: String
    let mode: TranscriptionMode
    let timestamp: Date
    let audioDuration: TimeInterval?
    
    init(id: UUID = UUID(), text: String, mode: TranscriptionMode, timestamp: Date = Date(), audioDuration: TimeInterval? = nil) {
        self.id = id
        self.text = text
        self.mode = mode
        self.timestamp = timestamp
        self.audioDuration = audioDuration
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: timestamp)
    }
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: timestamp)
    }
}

/// Gerencia o histórico de transcrições (últimos 50 itens)
class HistoryManager: ObservableObject {
    static let shared = HistoryManager()
    static let maxItems = 50
    
    @Published private(set) var items: [HistoryItem] = []
    private let settings = SettingsManager.shared
    private let saveKey = "transcription_history"
    
    private init() {
        loadHistory()
    }
    
    // MARK: - Public Methods
    
    func add(text: String, mode: TranscriptionMode, audioDuration: TimeInterval? = nil) {
        guard settings.enableHistory else { return }
        
        let item = HistoryItem(text: text, mode: mode, audioDuration: audioDuration)
        
        DispatchQueue.main.async {
            self.items.insert(item, at: 0)
            
            // Limitar a 50 itens
            if self.items.count > HistoryManager.maxItems {
                self.items = Array(self.items.prefix(HistoryManager.maxItems))
            }
            
            self.saveHistory()
        }
    }
    
    func delete(item: HistoryItem) {
        items.removeAll { $0.id == item.id }
        saveHistory()
    }
    
    func delete(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        saveHistory()
    }
    
    func clear() {
        items.removeAll()
        saveHistory()
    }
    
    func copyToClipboard(_ item: HistoryItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(item.text, forType: .string)
    }

    /// Retorna o último item do histórico (mais recente)
    var lastItem: HistoryItem? {
        items.first
    }

    /// Copia e cola o último item do histórico
    /// - Returns: O item colado, ou nil se o histórico estiver vazio
    @discardableResult
    func pasteLastItem() -> HistoryItem? {
        guard let item = lastItem else {
            print("[HistoryManager] No items in history to paste")
            return nil
        }

        // Use ClipboardHelper to copy and paste (preserves original clipboard)
        ClipboardHelper.copyAndPaste(item.text)
        print("[HistoryManager] Pasted last item: \(item.text.prefix(30))...")
        return item
    }
    
    // MARK: - Persistence
    
    private func saveHistory() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(data, forKey: saveKey)
    }
    
    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: saveKey),
              let savedItems = try? JSONDecoder().decode([HistoryItem].self, from: data) else {
            return
        }
        items = savedItems
    }
}
