
WITH CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > 1000
    GROUP BY c.c_custkey, c.c_name
),
SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    INNER JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        sp.total_available_qty,
        sp.avg_supply_cost
    FROM SupplierParts sp
    INNER JOIN supplier s ON sp.s_suppkey = s.s_suppkey
    WHERE sp.avg_supply_cost < (SELECT AVG(ps.ps_supplycost) FROM partsupp ps)
)
SELECT 
    co.c_name AS customer_name,
    co.order_count,
    COALESCE(hvs.total_available_qty, 0) AS supplier_total_available_qty,
    hvs.avg_supply_cost AS supplier_avg_supply_cost,
    CASE 
        WHEN co.total_spent > 10000 THEN 'High Spender'
        WHEN co.total_spent BETWEEN 5000 AND 10000 THEN 'Medium Spender'
        ELSE 'Low Spender'
    END AS spending_category
FROM CustomerOrders co
LEFT JOIN HighValueSuppliers hvs ON co.c_custkey = hvs.s_suppkey
WHERE co.order_count > 0
ORDER BY co.total_spent DESC, co.c_name;
