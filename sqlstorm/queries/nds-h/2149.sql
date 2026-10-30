
WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_custkey, 
           ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rnk
    FROM orders o
), RecentOrders AS (
    SELECT ro.o_orderkey, ro.o_orderdate, ro.o_custkey
    FROM RankedOrders ro
    WHERE ro.rnk <= 5
), SupplierPartData AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, ps.ps_supplycost, 
           p.p_name, s.s_name, s.s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost ASC) AS min_cost_rank
    FROM partsupp ps 
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
), CustomerOrderSummary AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent,
           COUNT(DISTINCT o.o_orderkey) AS total_orders, 
           AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    co.c_custkey, co.c_name, co.total_orders, co.total_spent, 
    CASE 
        WHEN co.total_spent > 10000 THEN 'High Value'
        WHEN co.total_spent BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value,
    COUNT(DISTINCT psd.ps_suppkey) AS unique_suppliers,
    SUM(CASE WHEN psd.min_cost_rank = 1 THEN psd.ps_supplycost ELSE 0 END) AS total_min_supply_cost,
    AVG(psd.ps_supplycost) AS avg_supply_cost
FROM CustomerOrderSummary co
LEFT JOIN RecentOrders ro ON co.c_custkey = ro.o_custkey
LEFT JOIN SupplierPartData psd ON ro.o_orderkey = psd.ps_partkey
WHERE co.total_orders > 0 AND psd.ps_availqty > 0
GROUP BY co.c_custkey, co.c_name, co.total_orders, co.total_spent
ORDER BY co.total_spent DESC;
