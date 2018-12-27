
import Foundation

enum NewResult<T> {
    case value(T)
    case error(Error)
}

class Future<T> {
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
}

extension Future {
    func chained<NextValue>(with closure: @escaping (T) throws -> Future<NextValue>) -> Future<NextValue> {
        let promise = Promise<NextValue>()

        observe { result in
            switch result {
            case .value(let value):
                do {
                    let future = try closure(value)

                    future.observe { result in
                        switch result {
                        case .value(let value):
                            promise.resolve(with: value)
                        case .error(let error):
                            promise.reject(with: error)
                        }
                    }
                } catch {
                    promise.reject(with: error)
                }
            case .error(let error):
                promise.reject(with: error)
            }
        }

        return promise
    }

    func transformed<NextValue>(with closure: @escaping (T) throws -> NextValue) -> Future<NextValue> {
        return chained { value in
            return try Promise(value: closure(value))
        }
    }
}

class Promise<T>: Future<T> {
    init(value: T? = nil) {
        super.init()
        result = value.map(NewResult.value)
    }

    func resolve(with value: T) {
        result = .value(value)
    }

    func reject(with error: Error) {
        result = .error(error)
    }
}
