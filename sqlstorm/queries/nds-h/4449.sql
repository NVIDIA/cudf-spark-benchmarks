WITH SupplierCost AS (
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
HighDemandParts AS (
    SELECT 
        li.l_partkey,
        SUM(li.l_quantity) AS total_quantity
    FROM 
        lineitem li
    WHERE 
        li.l_shipdate >= '1997-01-01'
    GROUP BY 
        li.l_partkey
    HAVING 
        SUM(li.l_quantity) > 1000
),
SupplierPerformance AS (
    SELECT 
        pc.p_partkey,
        pc.p_name,
        sc.total_supply_cost,
        hp.total_quantity
    FROM 
        part pc
    LEFT JOIN 
        SupplierCost sc ON pc.p_partkey = sc.s_suppkey
    LEFT JOIN 
        HighDemandParts hp ON pc.p_partkey = hp.l_partkey
)
SELECT 
    sp.p_partkey,
    sp.p_name,
    COALESCE(sp.total_supply_cost, 0) AS total_supply_cost,
    COALESCE(sp.total_quantity, 0) AS total_quantity,
    CASE 
        WHEN sp.total_quantity IS NOT NULL THEN 'High Demand'
        ELSE 'Low Demand'
    END AS demand_category
FROM 
    SupplierPerformance sp
WHERE 
    (sp.total_supply_cost IS NULL OR sp.total_supply_cost >= 5000)
ORDER BY 
    total_supply_cost DESC, 
    total_quantity DESC;