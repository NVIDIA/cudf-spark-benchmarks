WITH SupplierTotal AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
NationDetails AS (
    SELECT n.n_nationkey, n.n_name, r.r_name AS region_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    nd.region_name,
    COUNT(DISTINCT co.c_custkey) AS total_customers,
    COALESCE(SUM(co.total_spent), 0) AS total_spending,
    COALESCE(AVG(co.order_count), 0) AS average_orders,
    MAX(st.total_supply_cost) AS highest_supply_cost
FROM NationDetails nd
LEFT JOIN CustomerOrders co ON nd.n_nationkey = co.c_custkey
LEFT JOIN SupplierTotal st ON st.s_suppkey = (
    SELECT ps.ps_suppkey 
    FROM partsupp ps 
    JOIN part p ON ps.ps_partkey = p.p_partkey 
    WHERE p.p_size > 10 
    ORDER BY ps.ps_supplycost DESC 
    LIMIT 1
)
GROUP BY nd.region_name
HAVING COUNT(DISTINCT co.c_custkey) > 0 OR MAX(st.total_supply_cost) IS NOT NULL
ORDER BY total_spending DESC, region_name;
