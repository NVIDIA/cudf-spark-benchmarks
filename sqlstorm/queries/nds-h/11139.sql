WITH SupplierPart AS (
    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
),
OrderLine AS (
    SELECT o.o_orderkey, l.l_partkey, l.l_extendedprice, l.l_discount
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
)
SELECT sp.s_name, ol.o_orderkey, SUM(ol.l_extendedprice * (1 - ol.l_discount)) AS revenue
FROM SupplierPart sp
JOIN OrderLine ol ON sp.ps_partkey = ol.l_partkey
GROUP BY sp.s_name, ol.o_orderkey
ORDER BY revenue DESC
LIMIT 10;
