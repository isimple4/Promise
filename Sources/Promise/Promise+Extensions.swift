

import Foundation

// All extensions for promise.
extension Future {
    // prepare  Future by caller
    public func flatMap<NextV>(_ closure: @escaping (V) -> Future<NextV>) -> Future<NextV> {
        let p = Promise<NextV>()
        
        observe { result in
            switch result {
            case .success(let value):
                let future = closure(value)
                
                future.observe { result in
                    switch result {
                    case .success(let value):
                        p.fullfill(with: value)
                    case .failure(let error):
                        p.reject(with: error)
                    }
                }
                
            case .failure(let error):
                p.reject(with: error)
            }
        }
        
        return p
    }
    
    /// simple transform
    public func map<NextV>(_ closure: @escaping (V) -> NextV) -> Future<NextV> {
        let p = Promise<NextV>()
        
        observe { result in
            switch result {
            case .success(let value):
                p.fullfill(with: closure(value))
                
            case .failure(let error):
                p.reject(with: error)
            }
        }
        
        return p
    }
}

extension Future {
    public func then<NextV>(_ closure: @escaping (V) -> Future<NextV>) -> Future<NextV> {
        return self.flatMap(closure)
    }
}

extension Future {
    @discardableResult
    public func get(_ closure: @escaping (V) -> Void) -> Future<V> {
        return self.map {
            closure($0)
            return $0
        }
    }
}


public enum PromsieErrors: Error {
    /// validation not passed
    case notValid
}


extension Future {
    @discardableResult
    public func done(_ closure: @escaping (V) -> Void) -> Future<Void> {
        let p = Promise<Void>()
        
        self.observe { result in
            switch result {
            case .success(let value):
                closure(value)
                p.fullfill(with: ())
            case .failure(let error):
                p.reject(with: error)
            }
        }
        return p
    }
}

extension Future {
    @discardableResult
    public func `catch`(_ callback: @escaping (Error) -> Void) -> Future<V> {
        let p = Promise<V>()
        
        self.observe { result in
            switch result {
            case .success(let v):
                p.fullfill(with: v)
            case .failure(let e):
                callback(e)
                p.reject(with: e)
            }
        }
        
        return p
    }
}

extension Future {
    public func onFullfill(_ callback: @escaping (V) -> Void) {
        self.observe { result in
            if case .success(let v) = result {
                callback(v)
            }
        }
    }
    
    public func onReject(_ callback: @escaping (Error) -> Void) {
        self.observe { result in
            if case .failure(let e) = result {
                callback(e)
            }
        }
    }
}

extension Future {
    @discardableResult
    public func always(_ callback: @escaping () -> Void) -> Future<V> {
        let p = Promise<V>()
        
        self.observe { result in
            callback()
            p.complete(with: result)
        }
        
        return p
    }
}

extension Future {
    @discardableResult
    public func delay(_ seconds: Double, on queue: DispatchQueue) -> Future<V> {
        let p = Promise<V>()
        
        self.observe { result in
            queue.asyncAfter(deadline: .now() + seconds, execute: {
                p.complete(with: result)
            })
        }
        
        return p
    }
}

extension Future {
    @discardableResult
    public func validate(_ callback: @escaping (V) -> Bool) -> Future<V> {
        let p = Promise<V>()
        
        self.observe { result in
            switch result {
            case .success(let v):
                if callback(v) {
                    p.fullfill(with: v)
                } else {
                    p.reject(with: PromsieErrors.notValid)
                }
            case .failure(let e):
                p.reject(with: e)
            }
        }
        
        return p
    }
}

extension Future {
    @discardableResult
    public func recover(_ callback: @escaping (Error) -> V) -> Future<V> {
        let p = Promise<V>()
        
        self.observe { result in
            switch result {
            case .success(let v):
                p.fullfill(with: v)
            case .failure(let e):
                p.fullfill(with: callback(e))
            }
        }
        
        return p
    }
    
}

extension Future {
    /// Switch to specific queue
    public func on(_ queue: DispatchQueue) -> Future<V> {
        let p = Promise<V>()
        
        self.observe { result in
            queue.async {
                p.complete(with: result)
            }
        }
        
        return p
    }
}


