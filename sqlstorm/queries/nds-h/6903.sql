WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
TopSuppliers AS (
    SELECT r.r_regionkey, r.r_name, rs.s_suppkey, rs.s_name, rs.s_acctbal
    FROM region r
    JOIN RankedSuppliers rs ON r.r_regionkey = rs.s_suppkey
    WHERE rs.rank <= 5
),
LocalizedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, cs.c_nationkey
    FROM orders o
    JOIN customer cs ON o.o_custkey = cs.c_custkey
)
SELECT ts.r_name AS region_name, COUNT(DISTINCT lo.o_orderkey) AS total_orders,
       SUM(lo.o_totalprice) AS total_revenue
FROM TopSuppliers ts
JOIN LocalizedOrders lo ON ts.s_suppkey = lo.c_nationkey
GROUP BY ts.r_name
ORDER BY total_revenue DESC;
