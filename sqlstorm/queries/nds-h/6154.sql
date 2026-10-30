WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           RANK() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_acctbal IS NOT NULL)
),
LargeOrders AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000
),
TopSuppliers AS (
    SELECT rs.s_suppkey, rs.s_name
    FROM RankedSuppliers rs
    WHERE rs.supplier_rank <= 5
)
SELECT lo.o_orderkey, lo.total_order_value, ts.s_name
FROM LargeOrders lo
JOIN lineitem l ON lo.o_orderkey = l.l_orderkey
JOIN TopSuppliers ts ON l.l_suppkey = ts.s_suppkey
ORDER BY lo.total_order_value DESC
LIMIT 10;
