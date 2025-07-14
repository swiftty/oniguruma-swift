import Testing

@preconcurrency @testable import COniguruma

struct OnigmoError: Error {
    var status: Int
    var message: String

    init(status: Int32) {
        self.status = Int(status)

        let format = onig_error_code_to_format(status)
        self.message = String(cString: format!)
    }
}

class COnigurumaTests {
    private var utf8Encoding = OnigEncodingUTF8

    init() {
        withUnsafeMutablePointer(to: &utf8Encoding) { ptr in
            var encodings: [OnigEncoding?] = [ptr]
            onig_initialize(&encodings, 1)
        }
    }

    @Test
    func `check simple regex`() throws {
        var onig: OnigRegex?

        let pattern = "\\d{4}"

        let defaultSyntax = OnigDefaultSyntax
        var error = OnigErrorInfo()
        try pattern.withOnigUCharString { pointer, length in
            let result = onig_new(
                &onig,
                pointer,
                pointer.advanced(by: length),
                ONIG_OPTION_NONE,
                &utf8Encoding,
                defaultSyntax,
                &error
            )

            guard result == ONIG_NORMAL else {
                throw OnigmoError(status: result)
            }
        }
        defer {
            onig_free(onig)
        }

        // matching
        func search(_ string: String) throws -> [Range<String.Index>] {
            let region: UnsafeMutablePointer<OnigRegion>! = onig_region_new()
            defer {
                onig_region_free(region, 1)
            }

            return string.withOnigUCharString { pointer, length in
                var ranges: [Range<String.Index>] = []
                var start = pointer
                let end = pointer.advanced(by: length)

                while
                    start < end,
                    case let result = onig_search(onig, pointer, end, start, end, region, ONIG_OPTION_NONE),
                    result >= 0
                {
                    guard let range = Range(region, in: string) else {
                        continue
                    }
                    ranges.append(range)
                    start = start.advanced(by: Int(region.pointee.end.pointee))
                }

                return ranges
            }
        }

        func check(_ target: String) throws -> [String] {
            let ranges = try search(target)
            return ranges.compactMap { range in
                String(target[range])
            }
        }

        #expect(try check("2025 01 01") == ["2025"])
        #expect(try check("2025 2026 01") == ["2025", "2026"])
        #expect(try check("0") == [])
    }
}

extension Range {
    init?<S: StringProtocol>(_ region: UnsafePointer<OnigRegion>, in string: S) where Bound == S.Index {
        let utf8 = string.utf8

        let beginOffset = region.pointee.beg!
        let endOffset = region.pointee.end!

        func index(fromUTF8Offset offset: Int) -> String.Index {
            let utf8Index = utf8.index(utf8.startIndex, offsetBy: offset)
            return utf8Index
        }

        guard beginOffset.pointee != ONIG_REGION_NOTPOS,
              endOffset.pointee != ONIG_REGION_NOTPOS else {
            return nil
        }
        let beginIndex = index(fromUTF8Offset: Int(beginOffset.pointee))
        let endIndex = index(fromUTF8Offset: Int(endOffset.pointee))

        self = beginIndex..<endIndex
    }
}

private extension String {
    func withOnigUCharString<R>(_ body: (UnsafePointer<OnigUChar>, Int) throws -> R) rethrows -> R {
        let count = utf8.count

        return try withCString { pointer in
            try pointer.withMemoryRebound(to: OnigUChar.self, capacity: count) { pointer in
                try body(pointer, count)
            }
        }
    }
}
