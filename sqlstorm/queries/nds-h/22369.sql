
WITH  HighValueSuppliers AS (
    SELECT s.s_suppkey,
           s.s_name,
           s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
    WHERE s.s_acctbal > 5000
),
PartSupplierDetails AS (
    SELECT ps.ps_partkey,
           ps.ps_suppkey,
           SUM(ps.ps_availqty) AS total_available,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    JOIN HighValueSuppliers hvs ON ps.ps_suppkey = hvs.s_suppkey
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
OrderLineDetails AS (
    SELECT o.o_orderkey,
           COUNT(l.l_orderkey) AS total_lines,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O' 
    GROUP BY o.o_orderkey
)
SELECT p.p_partkey,
       p.p_name,
       COALESCE(MAX(pbd.total_available), 0) AS max_available,
       COALESCE(MIN(pbd.avg_supply_cost), 99999.99) AS min_cost,
       CASE
           WHEN MAX(ol.total_lines) IS NULL THEN 'No Orders'
           ELSE 'Has Orders'
       END AS order_status,
       SUM(ol.total_revenue) AS total_revenue
FROM part p
LEFT JOIN PartSupplierDetails pbd ON p.p_partkey = pbd.ps_partkey
LEFT JOIN OrderLineDetails ol ON ol.o_orderkey IN (
    SELECT o.o_orderkey
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'R' AND l.l_shipdate < DATE '1998-10-01' - INTERVAL '30 days'
)
GROUP BY p.p_partkey, p.p_name
HAVING SUM(ol.total_revenue) > (
    SELECT COALESCE(AVG(total_revenue), 0)
    FROM (
        SELECT SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
        FROM lineitem l
        GROUP BY l.l_orderkey
    ) AS subquery
) OR NULLIF(MAX(pbd.total_available), 0) IS NULL
ORDER BY p.p_partkey, total_revenue DESC NULLS LAST;
