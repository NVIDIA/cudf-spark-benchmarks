WITH EnhancedSupplier AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUBSTRING(s.s_address, 1, 20) AS short_address,
        r.r_name AS region_name,
        CONCAT(s.s_name, ' (', s.s_phone, ')') AS detailed_info,
        LENGTH(s.s_comment) AS comment_length
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
SupplierPerformance AS (
    SELECT 
        e.s_suppkey,
        e.s_name,
        COUNT(ps.ps_partkey) AS supply_count,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        AVG(e.comment_length) AS average_comment_length,
        MAX(e.comment_length) AS longest_comment_length
    FROM 
        EnhancedSupplier e
    LEFT JOIN 
        partsupp ps ON e.s_suppkey = ps.ps_suppkey
    GROUP BY 
        e.s_suppkey, e.s_name
)
SELECT 
    sp.s_suppkey,
    sp.s_name,
    sp.supply_count,
    sp.total_supply_cost,
    sp.average_comment_length,
    sp.longest_comment_length,
    (CASE 
        WHEN sp.total_supply_cost > 10000 THEN 'High'
        WHEN sp.total_supply_cost BETWEEN 5000 AND 10000 THEN 'Medium'
        ELSE 'Low' 
     END) AS cost_category,
    (CASE 
        WHEN sp.average_comment_length > 50 THEN 'Verbose'
        ELSE 'Concise' 
     END) AS comment_style
FROM 
    SupplierPerformance sp
WHERE 
    sp.supply_count > 5
ORDER BY 
    sp.total_supply_cost DESC, 
    sp.s_name;
