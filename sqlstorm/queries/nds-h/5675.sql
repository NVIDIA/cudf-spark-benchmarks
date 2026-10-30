
WITH CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS order_count, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierParts AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
NationMetrics AS (
    SELECT 
        n.n_nationkey, 
        n.n_name, 
        SUM(co.order_count) AS total_orders,
        SUM(sp.total_supply_cost) AS total_supply_cost
    FROM 
        nation n
    LEFT JOIN 
        CustomerOrders co ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey IN (SELECT DISTINCT c_custkey FROM customer) LIMIT 1)
    LEFT JOIN 
        SupplierParts sp ON n.n_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey IN (SELECT DISTINCT ps.ps_suppkey FROM partsupp ps) LIMIT 1)
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    nm.n_nationkey, 
    nm.n_name, 
    nm.total_orders, 
    nm.total_supply_cost
FROM 
    NationMetrics nm
WHERE 
    nm.total_orders > 0 AND nm.total_supply_cost > 0
ORDER BY 
    nm.total_orders DESC, 
    nm.total_supply_cost DESC;
