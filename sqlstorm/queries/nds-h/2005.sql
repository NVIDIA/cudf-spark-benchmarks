WITH SupplierStats AS (
    SELECT 
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_nationkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_nationkey
),
NationStats AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COALESCE(ss.total_supply_cost, 0) AS total_supply_cost,
        COALESCE(co.order_count, 0) AS order_count,
        COALESCE(co.avg_order_value, 0) AS avg_order_value,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY COALESCE(co.avg_order_value, 0) DESC) AS rank
    FROM 
        nation n
    LEFT JOIN 
        SupplierStats ss ON n.n_nationkey = ss.s_nationkey
    LEFT JOIN 
        CustomerOrders co ON n.n_nationkey = co.c_nationkey
)
SELECT 
    n.n_name,
    n.total_supply_cost,
    n.order_count,
    n.avg_order_value,
    CASE 
        WHEN n.order_count > 10 THEN 'High'
        WHEN n.order_count BETWEEN 5 AND 10 THEN 'Medium'
        ELSE 'Low'
    END AS demand_category
FROM 
    NationStats n
WHERE 
    n.rank = 1
ORDER BY 
    n.total_supply_cost DESC
LIMIT 10;
