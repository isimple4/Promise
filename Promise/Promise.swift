
import Foundation

// Add var for easier result value/error getter
extension Result {
    /// result value, nil if no value
    var value: Success? {
        switch self {
        case .success(let value):
            return value
        default: return nil
        }
    }

    /// result error, nil if no error
    var error: Failure? {
        switch self {
        case .failure(let error):
            return error
        default: return nil
        }
    }
}

/**
 Actual stores for promise, provide functions to add to observation list.
*/
public class Future<V> {
    /**
     Final result, will fire  calls to callback list when value is set.
     After calls, _isPending changes to false. No more callbacks will be triggered
    */
    fileprivate var _result: Result<V, Error>? {
        didSet {
            _result.map(report)
            _isPending = false
        }
    }
    
    /// Stores for observation callback list.
    private lazy var _callbacks = [(Result<V, Error>) -> Void]()
    
    /// Default true. Turn to false if self promise fulfilled/rejected.
    var _isPending: Bool = true

    /// Trigger callbacks to list
    private func report(result: Result<V, Error>) {
        for callback in _callbacks {
            callback(result)
        }
    }
    
    /// Add callback to list
    func observe(with callback: @escaping (Result<V, Error>) -> Void) {
        _callbacks.append(callback)
        _result.map(callback)
    }
}

// Helper functions
extension Future {
    /// Result getter
    public func debugResult() -> Result<V, Error>? {
        return _result
    }
    
    /// Result value getter helper
    public func debugValue() -> V? {
        return debugResult()?.value
    }
    
    /// Result error getter helper
    public func debugError() -> Error? {
        return debugResult()?.error
    }
}

// Inheritted from Future, promise functions to update self result.
public class Promise<V>: Future<V> {
    /// Success with result
    public func fullfill(with value: V) {
        guard _isPending else { return }
        _result = .success(value)
    }
    
    /// Fail with error
    public func reject(with error: Error) {
        guard _isPending else { return }
        _result = .failure(error)
    }
}




