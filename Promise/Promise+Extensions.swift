

import Foundation

// All extensions for promise.
extension Future {
    // prepare  Future by caller
    public func flatMap<NextV>(_ closure: @escaping (V) -> Future<NextV, E>) -> Future<NextV, E> {
        let p = Promise<NextV, E>()
        
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
    public func map<NextV>(_ closure: @escaping (V) -> NextV) -> Future<NextV, E> {
        let p = Promise<NextV, E>()
        
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
    public func then<NextV>(_ closure: @escaping (V) -> Future<NextV, E>) -> Future<NextV, E> {
        return self.flatMap(closure)
    }
}

extension Future {
    @discardableResult
    public func get(_ closure: @escaping (V) -> Void) -> Future<V, E> {
        return self.map {
            closure($0)
            return $0
        }
    }
}

extension Future {
    @discardableResult
    public func done(_ closure: @escaping (V) -> Void) -> Future<Void, E> {
        let p = Promise<Void, E>()

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
    public func `catch`(_ callback: @escaping (Error)->()) -> Future<V, E> {
        let p = Promise<V, E>()
        
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

