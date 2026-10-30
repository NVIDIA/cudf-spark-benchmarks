WITH RankedSuppliers AS (
    SELECT 
        s.s_name,
        p.p_name,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
), FilteredSuppliers AS (
    SELECT 
        s_name,
        p_name,
        ps_supplycost
    FROM 
        RankedSuppliers
    WHERE 
        rn <= 3
), AggregatedSuppliers AS (
    SELECT 
        p_name,
        COUNT(s_name) AS supplier_count,
        SUM(ps_supplycost) AS total_supply_cost,
        AVG(ps_supplycost) AS avg_supply_cost
    FROM 
        FilteredSuppliers
    GROUP BY 
        p_name
)
SELECT 
    p.p_name,
    p.p_type,
    p.p_brand,
    a.supplier_count,
    a.total_supply_cost,
    a.avg_supply_cost,
    CASE 
        WHEN a.avg_supply_cost < 100 THEN 'Low Cost'
        WHEN a.avg_supply_cost BETWEEN 100 AND 500 THEN 'Medium Cost'
        ELSE 'High Cost'
    END AS cost_category,
    CONCAT('Product ', p.p_name) AS product_description
FROM 
    part p
LEFT JOIN 
    AggregatedSuppliers a ON p.p_name = a.p_name
WHERE 
    p.p_container LIKE '%BOX%'
ORDER BY 
    a.total_supply_cost DESC NULLS LAST;
