WITH SupplierPerformance AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_qty,
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
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'F' OR o.o_orderstatus IS NULL
    GROUP BY 
        c.c_custkey, c.c_name
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
)
SELECT 
    sp.s_suppkey,
    sp.s_name,
    sp.total_available_qty,
    sp.avg_supply_cost,
    co.total_orders,
    co.total_spent
FROM 
    SupplierPerformance sp
JOIN 
    CustomerOrders co ON sp.part_count > 5
LEFT JOIN 
    HighValueSuppliers hvs ON sp.s_suppkey = hvs.s_suppkey
WHERE 
    (hvs.s_suppkey IS NOT NULL OR sp.avg_supply_cost < 500.00)
AND 
    (sp.total_available_qty IS NOT NULL OR sp.avg_supply_cost IS NOT NULL)
ORDER BY 
    sp.total_available_qty DESC, co.total_spent DESC
LIMIT 100;
