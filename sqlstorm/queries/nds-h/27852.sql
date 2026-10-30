WITH PartAggregates AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
SupplierCounts AS (
    SELECT 
        p.p_partkey,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey
),
DetailedMetrics AS (
    SELECT 
        pa.p_partkey,
        pa.p_name,
        pa.total_available,
        pa.avg_supply_cost,
        COALESCE(sc.supplier_count, 0) AS supplier_count
    FROM 
        PartAggregates pa
    LEFT JOIN 
        SupplierCounts sc ON pa.p_partkey = sc.p_partkey
)
SELECT 
    dm.p_partkey,
    dm.p_name,
    dm.total_available,
    dm.avg_supply_cost,
    dm.supplier_count,
    CONCAT('Part: ', dm.p_name, 
           ' | Total Available: ', dm.total_available, 
           ' | Avg Supply Cost: ', ROUND(dm.avg_supply_cost, 2), 
           ' | Suppliers: ', dm.supplier_count) AS summary
FROM 
    DetailedMetrics dm
WHERE 
    dm.total_available > 100
ORDER BY 
    dm.avg_supply_cost DESC, 
    dm.total_available DESC;
