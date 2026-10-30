WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts_supply
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TotalParts AS (
    SELECT 
        COUNT(DISTINCT p.p_partkey) AS total_parts
    FROM 
        part p
)
SELECT 
    cs.c_name,
    ss.s_name,
    cs.total_spent,
    ss.total_available,
    ss.avg_supply_cost,
    tp.total_parts AS total_parts_inventory,
    CASE 
        WHEN cs.order_count > 0 THEN 'Active'
        ELSE 'Inactive'
    END AS customer_status,
    RANK() OVER (PARTITION BY cs.c_custkey ORDER BY cs.total_spent DESC) AS spend_rank
FROM 
    CustomerOrders cs
FULL OUTER JOIN 
    SupplierStats ss ON cs.c_custkey = ss.s_suppkey
CROSS JOIN 
    TotalParts tp
WHERE 
    cs.total_spent > 1000 
    OR ss.total_available IS NULL
ORDER BY 
    cs.c_name, ss.avg_supply_cost DESC;
