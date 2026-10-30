
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE sh.level < 10
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, 
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
PartSupplierSummary AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_available,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
FilteredParts AS (
    SELECT p.p_partkey, p.p_name, 
           CASE 
               WHEN ps.total_available IS NULL THEN 'No Supply'
               WHEN ps.total_available < 100 THEN 'Low Supply'
               ELSE 'Sufficient Supply'
           END AS availability_status
    FROM part p
    LEFT JOIN PartSupplierSummary ps ON p.p_partkey = ps.p_partkey
)
SELECT c.c_name, c.order_count, c.total_spent, 
       ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY c.total_spent DESC) AS rank,
       ph.availability_status
FROM CustomerOrders c
LEFT JOIN FilteredParts ph ON c.c_custkey = (
    SELECT o.o_custkey 
    FROM orders o 
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey 
    WHERE l.l_quantity > 10 
    LIMIT 1
)
WHERE c.order_count > 5
ORDER BY c.total_spent DESC;
