

struct QCategory {
    var name:String
    init(name:String) {
        self.name = name
    }
}

extension QCategory: ExpressibleByStringLiteral {
    init(stringLiteral value: String) {
        self.name = value
    }
    init(unicodeScalarLiteral value: String) {
        self.init(name: value)
    }
    init(extendedGraphemeClusterLiteral value: String) {
        self.init(name: value)
    }
}
