
import Foundation

public enum NewResult<T> {
    case success(T)
    case failure(Error)
}

extension NewResult {
    var value: T? {
        switch self {
        case .success(let value):
            return value
        default: return nil
        }
    }
    
    var error: Error? {
        switch self {
        case .failure(let error):
            return error
        default: return nil
        }
    }
}

public class Future<T> {
    fileprivate var result: NewResult<T>? {
        didSet { result.map(report) }
    }
    
    private lazy var callbacks = [(NewResult<T>) -> Void]()

    func observe(with callback: @escaping (NewResult<T>) -> Void) {
        callbacks.append(callback)
        result.map(callback)
    }

    private func report(result: NewResult<T>) {
        for callback in callbacks {
            callback(result)
        }
    }
    
    public func debugResult() -> NewResult<T>? {
        return result
    }
    
    public func debugValue() -> T? {
        return debugResult()?.value
    }
    
    public func debugError() -> Error? {
        return debugResult()?.error
    }
}

class Promise<T>: Future<T> {
    init(value: T? = nil) {
        super.init()
        result = value.map(NewResult.success)
    }
    
    func fullfill(with value: T) {
        result = .success(value)
    }
    
    func reject(with error: Error) {
        result = .failure(error)
    }
}

extension Future {
    // prepare  Future by caller
    func flatMap<U>(_ closure: @escaping (T) throws -> Future<U>) -> Future<U> {
        let promise = Promise<U>()

        observe { result in
            switch result {
            case .success(let value):
                do {
                    let future = try closure(value)

                    future.observe { result in
                        switch result {
                        case .success(let value):
                            promise.fullfill(with: value)
                        case .failure(let error):
                            promise.reject(with: error)
                        }
                    }
                } catch {
                    promise.reject(with: error)
                }
            case .failure(let error):
                promise.reject(with: error)
            }
        }

        return promise
    }

    /// simple transform
    func map<U>(_ closure: @escaping (T) throws -> U) -> Future<U> {
        return flatMap { value in
            return try Promise(value: closure(value))
        }
    }
}

extension Future {
    func then<U>(_ closure: @escaping (T) throws -> Future<U>) -> Future<U> {
        return self.flatMap(closure)
    }
}


