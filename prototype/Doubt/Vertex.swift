public enum Vertex<Element> {
	indirect case XY(Element, Memo<Vertex>, Memo<Vertex>)
	case End

	public func analysis<Result>(@noescape ifXY ifXY: (Element, Memo<Vertex>, Memo<Vertex>) -> Result, @noescape ifEnd: () -> Result) -> Result {
		switch self {
		case let .XY(a, x, y):
			return ifXY(a, x, y)
		case .End:
			return ifEnd()
		}
	}

	public var element: Element? {
		switch self {
		case let .XY(a, _, _):
			return a
		case .End:
			return nil
		}
	}

	public var right: Memo<Vertex> {
		switch self {
		case let .XY(_, xs, _):
			return xs
		case .End:
			return Memo(evaluated: .End)
		}
	}

	public var down: Memo<Vertex> {
		switch self {
		case let .XY(_, _, ys):
			return ys
		case .End:
			return Memo(evaluated: .End)
		}
	}

	public var diagonal: Memo<Vertex> {
		return right.flatMap { $0.down }
	}
	

	public init<S1: SequenceType, S2: SequenceType>(rows: S1, columns: S2, combine: (S1.Generator.Element, S2.Generator.Element) -> Element) {
		let rows = Stream(sequence: rows)
		let columns = Stream(sequence: columns)
		self = columns
			.map { b in rows.map { a in (a, b) } }
			.fold(Vertex<(S1.Generator.Element, S2.Generator.Element)>.End) {
				$0.fold(($1, .End)) {
					($1.flatMap { row, _ in row }.flatMap { $0.right }, .XY($0, $1.map { _, column in column }, $1.flatMap { row, _ in row }))
				}.1
			}
			.map(combine)
	}


	public func map<Other>(transform: Element -> Other) -> Vertex<Other> {
		switch self {
		case let .XY(xy, xs, ys):
			return .XY(transform(xy), xs.map { $0.map(transform) }, ys.map { $0.map(transform) })
		case .End:
			return .End
		}
	}
}
