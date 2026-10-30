
WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
TopSuppliers AS (
    SELECT rs.s_suppkey, rs.s_name, rs.s_acctbal, n.n_name AS nation_name
    FROM RankedSuppliers rs
    JOIN nation n ON rs.rank <= 3
    WHERE rs.rank <= 3
),
TotalSales AS (
    SELECT l.l_suppkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY l.l_suppkey
),
SupplierPerformance AS (
    SELECT ts.s_suppkey, ts.s_name, ts.nation_name, COALESCE(tsales.total_revenue, 0) AS total_revenue
    FROM TopSuppliers ts
    LEFT JOIN TotalSales tsales ON ts.s_suppkey = tsales.l_suppkey
)
SELECT sp.nation_name, sp.s_name, sp.total_revenue
FROM SupplierPerformance sp
ORDER BY sp.nation_name, sp.total_revenue DESC
LIMIT 10;
