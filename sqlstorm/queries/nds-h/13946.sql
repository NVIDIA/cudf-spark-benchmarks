WITH SupplierPart AS (
    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
), OrderLine AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
)
SELECT sp.s_name, SUM(ol.total_revenue) AS total_revenue
FROM SupplierPart sp
JOIN OrderLine ol ON sp.ps_partkey = ol.o_orderkey
GROUP BY sp.s_name
ORDER BY total_revenue DESC
LIMIT 10;
