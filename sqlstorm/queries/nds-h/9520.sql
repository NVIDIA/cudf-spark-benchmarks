WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) as rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
TopSuppliers AS (
    SELECT rs.s_suppkey, rs.s_name, rs.s_acctbal, n.n_name AS nation_name
    FROM RankedSuppliers rs
    JOIN nation n ON rs.s_suppkey = n.n_nationkey
    WHERE rs.rank <= 5
),
OrderTotals AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey
)
SELECT ts.s_name, ts.nation_name, ot.total_order_value
FROM TopSuppliers ts
JOIN OrderTotals ot ON ts.s_suppkey = ot.o_custkey
WHERE ot.total_order_value > 50000
ORDER BY ot.total_order_value DESC;
