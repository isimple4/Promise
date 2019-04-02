
import Foundation

extension Result {
    var value: Success? {
        switch self {
        case .success(let value):
            return value
        default: return nil
        }
    }

    var error: Failure? {
        switch self {
        case .failure(let error):
            return error
        default: return nil
        }
    }
}

public class Future<V, E> where E : Error {
    fileprivate var _result: Result<V, E>? {
        didSet { _result.map(report) }
    }
    
    private lazy var callbacks = [(Result<V, E>) -> Void]()

    func observe(with callback: @escaping (Result<V, E>) -> Void) {
        callbacks.append(callback)
        _result.map(callback)
    }

    private func report(result: Result<V, E>) {
        for callback in callbacks {
            callback(result)
        }
    }
    
    public func debugResult() -> Result<V, E>? {
        return _result
    }
    
    public func debugValue() -> V? {
        return debugResult()?.value
    }
    
    public func debugError() -> Error? {
        return debugResult()?.error
    }
}

public class Promise<V, E>: Future<V, E> where E : Error {

    public func fullfill(with value: V) {
        _result = .success(value)
    }
    
    public func reject(with error: E) {
        _result = .failure(error)
    }
}




