WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name,
           ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
), TopSuppliers AS (
    SELECT r.r_regionkey, r.r_name, rs.s_suppkey, rs.s_name, rs.s_acctbal
    FROM RankedSuppliers rs
    JOIN region r ON rs.nation_name = r.r_name
    WHERE rs.rnk <= 5
), OrderDetails AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_totalprice, o.o_orderdate
)
SELECT ts.r_name AS region, ts.s_name AS supplier_name, od.o_orderkey, od.revenue, od.o_totalprice
FROM TopSuppliers ts
JOIN OrderDetails od ON ts.s_suppkey = od.o_orderkey
WHERE od.revenue > 10000
ORDER BY ts.r_name, ts.s_name, od.revenue DESC;
