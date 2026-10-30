WITH  OrderHierarchy AS (
    SELECT o_orderkey, o_totalprice, o_orderdate, o_orderstatus, o_custkey,
           ROW_NUMBER() OVER (PARTITION BY o_orderkey ORDER BY o_orderdate DESC) AS rn
    FROM orders
    WHERE o_orderdate >= '1997-01-01'
),
SupplierPerformance AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
           COUNT(DISTINCT ps.ps_partkey) AS total_parts,
           AVG(ps.ps_supplycost) AS avg_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
LineitemStats AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_price,
           COUNT(l.l_linenumber) AS line_count,
           MAX(l.l_shipdate) AS last_ship_date
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT 
    oh.o_orderkey, 
    oh.o_totalprice, 
    oh.o_orderdate, 
    sp.s_name, 
    sp.total_supply_cost, 
    ls.total_line_price,
    CASE 
        WHEN oh.o_orderstatus = 'F' THEN 'Complete' 
        ELSE 'Pending' 
    END AS order_status,
    COALESCE(ls.line_count, 0) AS line_count,
    (SELECT COUNT(*) FROM customer c WHERE c.c_nationkey = 
        (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'FRANCE')
    ) AS french_customers,
    (SELECT AVG(ps.ps_availqty) FROM partsupp ps WHERE ps.ps_supplycost < 100) AS avg_available_under_100
FROM OrderHierarchy oh
LEFT JOIN SupplierPerformance sp ON sp.total_parts > 10
LEFT JOIN LineitemStats ls ON oh.o_orderkey = ls.l_orderkey
WHERE oh.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_shipdate > '1997-01-01')
ORDER BY oh.o_orderdate DESC
LIMIT 100;