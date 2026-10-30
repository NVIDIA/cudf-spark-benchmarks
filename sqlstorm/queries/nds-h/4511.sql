WITH SupplierStats AS (
    SELECT s.s_suppkey,
           s.s_name,
           SUM(ps.ps_availqty) AS total_available,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
HighValueCustomers AS (
    SELECT c.c_custkey,
           c.c_name,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 10000
),
PartAnalytics AS (
    SELECT p.p_partkey,
           p.p_name,
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT ps.s_name AS Supplier_Name,
       pa.p_name AS Part_Name,
       pa.supplier_count,
       pa.avg_supply_cost,
       COALESCE(cu.total_spent, 0) AS Total_Spent_by_Customer
FROM SupplierStats ps
FULL OUTER JOIN PartAnalytics pa ON ps.total_cost > 100000
LEFT JOIN HighValueCustomers cu ON ps.s_suppkey = cu.c_custkey
WHERE pa.avg_supply_cost IS NOT NULL
   AND (pa.avg_supply_cost - ps.total_available) > 50
ORDER BY ps.s_name, pa.p_name;
