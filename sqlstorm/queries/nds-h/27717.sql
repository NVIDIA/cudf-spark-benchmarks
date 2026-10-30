WITH supplier_parts AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        p.p_size,
        p.p_brand,
        p.p_mfgr
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
aggregated_data AS (
    SELECT 
        supplier_name,
        COUNT(part_name) AS total_parts,
        SUM(ps_supplycost) AS total_supply_cost,
        AVG(ps_availqty) AS avg_availability,
        MAX(p_size) AS max_size,
        MIN(p_size) AS min_size
    FROM 
        supplier_parts
    GROUP BY 
        supplier_name
),
detailed_report AS (
    SELECT
        ad.supplier_name,
        ad.total_parts,
        ad.total_supply_cost,
        ad.avg_availability,
        ad.max_size,
        ad.min_size,
        CONCAT('Supplier ', ad.supplier_name, ' supplies ', ad.total_parts, 
               ' parts with an average availability of ', ROUND(ad.avg_availability, 2), 
               ' and a total supply cost of $', ROUND(ad.total_supply_cost, 2), '.') AS report_summary
    FROM 
        aggregated_data ad
    WHERE 
        ad.total_parts > 5 AND ad.avg_availability < 100
)
SELECT 
    report_summary
FROM 
    detailed_report
ORDER BY 
    total_supply_cost DESC;
