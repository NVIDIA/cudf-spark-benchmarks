WITH  OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice, 
           ROW_NUMBER() OVER (PARTITION BY o_custkey ORDER BY o_orderdate DESC) AS rnk
    FROM orders
), CustomerOrderPerformance AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, SUM(oh.o_totalprice) AS total_spent, 
           AVG(oh.o_totalprice) AS avg_order_value, 
           COUNT(oh.o_orderkey) AS order_count,
           COUNT(DISTINCT CASE WHEN oh.o_orderdate >= cast('1998-10-01' as date) - INTERVAL '30 days' THEN oh.o_orderkey END) AS recent_orders
    FROM customer c
    LEFT JOIN OrderHierarchy oh ON c.c_custkey = oh.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_acctbal
), SupplierPartSummary AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_availqty) AS total_available,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
           COUNT(DISTINCT p.p_partkey) AS parts_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name
)
SELECT cp.c_custkey, cp.c_name, cp.c_acctbal, cp.total_spent, cp.avg_order_value, 
       sp.s_suppkey, sp.s_name, sp.total_available, sp.total_supply_value, sp.parts_count
FROM CustomerOrderPerformance cp
FULL OUTER JOIN SupplierPartSummary sp ON cp.order_count = sp.parts_count
WHERE (cp.total_spent IS NOT NULL OR sp.total_supply_value IS NOT NULL) 
  AND (cp.c_acctbal > 500 OR sp.total_available < 100)
ORDER BY cp.total_spent DESC NULLS LAST, sp.total_supply_value ASC;