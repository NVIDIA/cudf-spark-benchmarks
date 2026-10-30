
WITH CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, c.total_spent,
           ROW_NUMBER() OVER (ORDER BY c.total_spent DESC) AS rank
    FROM CustomerOrders c
    WHERE c.total_spent IS NOT NULL
),
SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_availqty) AS total_available,
           COUNT(DISTINCT ps.ps_partkey) AS distinct_parts
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
PartPrices AS (
    SELECT p.p_partkey, p.p_name, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
)

SELECT tc.c_name AS Top_Customer, 
       s.s_name AS Supplier, 
       pp.p_name AS Part_Name, 
       pp.avg_supply_cost, 
       s.total_available,
       (CASE 
           WHEN s.total_available IS NULL OR pp.avg_supply_cost IS NULL THEN 'Unavailable' 
           ELSE 'Available' 
        END) AS Availability_Status
FROM TopCustomers tc
CROSS JOIN SupplierStats s
LEFT JOIN PartPrices pp ON pp.p_partkey IN (
    SELECT ps.ps_partkey
    FROM partsupp ps
    WHERE ps.ps_availqty > 0
    LIMIT 1
)
WHERE tc.rank <= 10
ORDER BY tc.total_spent DESC, s.total_available DESC;
