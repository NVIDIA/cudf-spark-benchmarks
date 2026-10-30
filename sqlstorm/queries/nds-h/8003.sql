
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rnk
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY s.s_suppkey, s.s_name, n.n_regionkey
),
HighCostSuppliers AS (
    SELECT s.s_suppkey, s.s_name
    FROM RankedSuppliers s
    WHERE s.rnk <= 5
),
TopCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
    ORDER BY total_spent DESC
    LIMIT 10
)
SELECT 
    hs.s_suppkey, 
    hs.s_name AS supplier_name, 
    tc.c_custkey, 
    tc.c_name AS customer_name,
    tc.total_spent
FROM HighCostSuppliers hs
JOIN TopCustomers tc ON tc.total_spent > (SELECT AVG(o.o_totalprice) FROM orders o)
ORDER BY tc.total_spent DESC;
