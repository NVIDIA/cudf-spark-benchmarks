WITH SupplierInfo AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name, r.r_name AS region_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
), OrderDetails AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_orderstatus, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1997-12-31'
    GROUP BY o.o_orderkey, o.o_orderdate, o.o_orderstatus
), TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, COUNT(od.o_orderkey) AS orders_count
    FROM SupplierInfo s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN OrderDetails od ON l.l_orderkey = od.o_orderkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING COUNT(od.o_orderkey) > 10
)
SELECT tsi.s_suppkey, tsi.s_name, tsi.orders_count, si.region_name
FROM TopSuppliers tsi
JOIN SupplierInfo si ON tsi.s_suppkey = si.s_suppkey
ORDER BY tsi.orders_count DESC, si.region_name ASC;