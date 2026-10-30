WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
           RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank_within_nation
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, SUM(o.o_totalprice) AS total_spent,
           RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rank_within_nation
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
)
SELECT r.r_name AS region_name, 
       s.s_name AS supplier_name, 
       c.c_name AS customer_name,
       s.total_supply_cost, 
       c.total_spent
FROM RankedSuppliers s
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN HighValueCustomers c ON n.n_nationkey = c.c_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE s.rank_within_nation <= 5 AND c.rank_within_nation <= 5
ORDER BY r.r_name, s.total_supply_cost DESC, c.total_spent DESC;
