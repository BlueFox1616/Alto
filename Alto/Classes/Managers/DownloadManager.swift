



import SwiftUI
import WebKit
import UniformTypeIdentifiers
import Observation

@Observable
class DownloadsList {
    
    private(set) var list = [DownloadItem]()
    
    public func add(_ download: DownloadItem) {
        // checks that download is not already in the list
        guard !list.contains(download) else {
            return
        }
        
        list.append(download)
    }
    
    public func remove(_ download: DownloadItem) {
        // checks that the list contains the download
        guard list.contains(download) else { return }
        
        list.removeAll(where:{ $0 == download })
    }
    
    public func clear() {
        list = []
    }
}

@Observable
public class DownloadManager: NSObject {
    static let shared = DownloadManager()
    var downloads: DownloadsList = .init()
    
    // The default location downloaded files will go
    private static var downloadLocation: URL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
    
    private override init() {
        
    }
    
    func download(response: URLResponse, fileName: String, location: URL = DownloadManager.downloadLocation, generateProxy: Bool = true) {
        guard let url = response.url else {
            return
        }
        
        download(url: url, fileName: fileName, location: location, generateProxy: generateProxy)
    }

    func download(url: URL,
                  fileName: String? = nil,
                  location: URL = DownloadManager.downloadLocation,
                  generateProxy: Bool = true) {
        
        let fileName = fileName ?? UUID().uuidString // Use "download /(int)"
        
        // Creates a item representing the download
        let downloadItem = DownloadItem(url: url, to: location, fileName: fileName, generateProxy: generateProxy)
        
        self.downloads.add(downloadItem)
    }
}

extension DownloadManager:  WKDownloadDelegate {
    public func download(
        _: WKDownload,
        decideDestinationUsing response: URLResponse,
        suggestedFilename: String,
        completionHandler: @escaping (URL?) -> Void
    ) {
        self.download(response: response, fileName: suggestedFilename)
        
        completionHandler(DownloadManager.downloadLocation)
    }
}

@Observable
class DownloadItemViewModel {
    let downloadItem: DownloadItem
    
    var list: DownloadsList {
        DownloadManager.shared.downloads
    }
    
    init(downloadItem: DownloadItem) {
        self.downloadItem = downloadItem
    }
    
    func close() {
        list.remove(self.downloadItem)
    }
    
    func openInFinder() {
        downloadItem.openInFinder()
    }
}

struct DownloadItemView: View {
    var model: DownloadItemViewModel
    
    var body: some View {
        HStack {
            Image(nsImage: model.downloadItem.fileIcon)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(model.downloadItem.fileName)
                    .lineLimit(1)
                
                HStack {
                    ProgressView(value: model.downloadItem.progressValue)
                        .frame(maxWidth: .infinity)
                    
                    Text(formatBytes(model.downloadItem.bytes, total: model.downloadItem.totalBytes))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Button {
                model.openInFinder()
            } label: {
                Image(systemName: "folder")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            
            Button {
                model.downloadItem.cancle()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
    
    private func formatBytes(_ current: Int64, total: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        
        if total > 0 {
            return "\(formatter.string(fromByteCount: current)) / \(formatter.string(fromByteCount: total))"
        } else {
            return formatter.string(fromByteCount: current)
        }
    }
}


@Observable
class DownloadItem: NSObject, URLSessionDownloadDelegate, DisplayableDownloadItem {
    let id = UUID()
    
    @ObservationIgnored private lazy var urlSession = URLSession(configuration: .default,
                                             delegate: self,
                                             delegateQueue: nil)
    
    var downloadTask: URLSessionDownloadTask?
    var proxyItem: ADKDownloadProxyItem?
    
    let downloadURL: URL
    let location: URL
    let documentURL: URL
    let shouldGenerateProxyDownload: Bool
    
    var bytes: Int64 = 0
    var totalBytes: Int64 = 0
    var progressValue: Double = 0.0
    let fileName: String
    
    var progress: Progress {
        let progress = Progress(totalUnitCount: 100)
        progress.completedUnitCount = Int64(progressValue * 100)
        return progress
    }
    
    var fileExtension: String {
        downloadURL.pathExtension
    }
    
    var fileIcon: NSImage {
        NSWorkspace.shared.icon(forFileType: fileExtension)
    }
    
    init(url: URL, to location: URL, fileName: String, generateProxy: Bool) {
        self.downloadURL = url
        self.location = location
        self.documentURL = location.appendingPathComponent(fileName)
        self.fileName = fileName
        self.shouldGenerateProxyDownload = generateProxy
        self.proxyItem = ADKDownloadProxyItem(location: documentURL, fileName: fileName)
        
        super.init()
        self.download()
    }
    
    func download() {
        if self.shouldGenerateProxyDownload {
            self.proxyItem?.createProxyDocument()
        }
        
        let downloadTask = urlSession.downloadTask(with: self.downloadURL)
        downloadTask.resume()
        self.downloadTask = downloadTask
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        do {
            // Handle file exists error
            if FileManager.default.fileExists(atPath: documentURL.path) {
                try FileManager.default.removeItem(at: documentURL)
            }
            
            try FileManager.default.moveItem(at: location, to: documentURL)
            self.proxyItem?.removeProxyDocument()
            
            DispatchQueue.main.async {
                self.progressValue = 1.0  // Set to complete
            }
        } catch {
            print("File error: \(error)")
        }
    }
    
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        
        if downloadTask == self.downloadTask {
            let calculatedProgress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            
            DispatchQueue.main.async {
                print("Progress update: \(calculatedProgress)")
                self.bytes = totalBytesWritten
                self.totalBytes = totalBytesExpectedToWrite
                self.progressValue = calculatedProgress
                
                if let proxyItem = self.proxyItem {
                    proxyItem.update(progress: calculatedProgress)
                }
            }
        }
    }
    
    func cancle() {
        downloadTask?.cancel()
        proxyItem?.removeProxyDocument()
    }
    
    func resume() {
        downloadTask?.resume()
    }
    
    func openInFinder() {
        NSWorkspace.shared.selectFile(documentURL.path, inFileViewerRootedAtPath: "")
    }
}

class ADKDownloadProxyItem {
    let location: URL
    let fileName: String
    let documentURL: URL
    
    public init(location: URL, fileName: String) {
        self.location = location
        self.fileName = fileName
        
        self.documentURL = location
            .appendingPathExtension(ADKDownloadDocument.fileExtension)
    }
    
    func createProxyDocument() {
        let document = ADKDownloadDocument()
        let uti = ADKDownloadDocument.documentTypeName
        document.save(to: self.documentURL, ofType: uti, for: .saveOperation) { error in
            print(error)
        }
    }
    
    func removeProxyDocument() {
        try? FileManager.default.removeItem(at: self.documentURL)
    }
    
    func update(progress: Double) {
        ADKDownloadDocument.setFractionCompletedExtendedAttribute(progress, onFileAt: self.documentURL)
    }
}

final class ADKDownloadDocument: NSDocument {
    static let fileExtension = "altodownload"
    static let documentTypeName = "co.alto.download"
    
    var content: String = ""
    
    override init() {
        super.init()
    }
    
    override class var autosavesInPlace: Bool {
        return true
    }
    
    override func data(ofType typeName: String) throws -> Data {
        return content.data(using: .utf8) ?? Data()
    }
    
    override func read(from data: Data, ofType typeName: String) throws {
        content = String(data: data, encoding: .utf8) ?? ""
    }
    
    /// Updates the file completion graph visible in Finder.
    static func setFractionCompletedExtendedAttribute(_ fractionCompleted: Double, onFileAt url: URL) {
        let extendedAttributesKey = FileAttributeKey("NSFileExtendedAttributes")
        
        if var attr = try? FileManager.default.attributesOfItem(atPath: url.path),
           var extAttr = attr[extendedAttributesKey] as? [String: Any]
        {
            // Add the progress in the file's extended attributes
            let progressData = "\(fractionCompleted)".data(using: .ascii)
            extAttr["com.apple.progress.fractionCompleted"] = progressData
            
            // Set back the extended attributes in the attributes
            attr[extendedAttributesKey] = extAttr
            
            // Set the creation date to the January 24th 1984 at 08:00Z for the finder to display the progress
            let magicDate = Date(timeIntervalSince1970: 443_779_200)
            attr[.creationDate] = magicDate
            
            // Save the attributes to the file
            try? FileManager.default.setAttributes(attr, ofItemAtPath: url.path)
        }
    }
}

protocol DisplayableDownloadItem {
    
}
