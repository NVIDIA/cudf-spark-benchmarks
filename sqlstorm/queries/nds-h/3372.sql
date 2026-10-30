
WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrderCounts AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    ss.s_name,
    COALESCE(cs.order_count, 0) AS order_count,
    ss.part_count,
    ss.total_available,
    ss.avg_supply_cost,
    CASE 
        WHEN ss.avg_supply_cost > 100 THEN 'High'
        WHEN ss.avg_supply_cost BETWEEN 50 AND 100 THEN 'Medium'
        ELSE 'Low'
    END AS cost_category
FROM 
    SupplierStats ss
LEFT JOIN 
    CustomerOrderCounts cs ON ss.s_suppkey = cs.c_custkey
WHERE 
    ss.total_available > 0 AND 
    ss.part_count > 5
ORDER BY 
    ss.avg_supply_cost DESC,
    ss.total_available ASC
LIMIT 10;
