WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, 
           CONCAT(s.s_name, ' (', s.s_address, ')') AS full_info,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_address, s.s_nationkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, c.c_address,
           COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_address
),
Nations AS (
    SELECT n.n_nationkey, n.n_name, r.r_name AS region_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    sd.full_info, 
    COALESCE(c.order_count, 0) AS order_count,
    COALESCE(c.total_spent, 0.00) AS total_spent,
    n.n_name AS nation_name,
    n.region_name,
    sd.total_cost
FROM SupplierDetails sd
LEFT JOIN CustomerOrders c ON sd.s_nationkey = c.c_custkey
JOIN Nations n ON sd.s_nationkey = n.n_nationkey
WHERE sd.total_cost > 10000
ORDER BY sd.total_cost DESC, c.total_spent DESC;
