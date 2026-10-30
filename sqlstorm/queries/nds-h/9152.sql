WITH SupplierCosts AS (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
OrderDetails AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
    GROUP BY o.o_orderkey
),
NationRegions AS (
    SELECT n.n_nationkey, r.r_regionkey
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT nr.r_regionkey, SUM(od.total_price) AS total_order_value, SUM(sc.total_cost) AS total_supplier_cost
FROM NationRegions nr
JOIN SupplierCosts sc ON nr.n_nationkey = sc.s_suppkey
JOIN OrderDetails od ON nr.n_nationkey = od.o_orderkey
GROUP BY nr.r_regionkey
ORDER BY total_order_value DESC, total_supplier_cost ASC
LIMIT 10;