WITH supplier_part_values AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * l.l_quantity) AS total_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey
),
nation_supplier_counts AS (
    SELECT 
        n.n_nationkey,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey
),
region_nation_total_value AS (
    SELECT 
        r.r_regionkey,
        SUM(spv.total_value) AS region_total_value
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        supplier_part_values spv ON s.s_suppkey = spv.s_suppkey
    GROUP BY 
        r.r_regionkey
)
SELECT 
    r.r_name,
    COUNT(DISTINCT n.n_nationkey) AS nation_count,
    rn.region_total_value
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    region_nation_total_value rn ON r.r_regionkey = rn.r_regionkey
GROUP BY 
    r.r_name, rn.region_total_value
ORDER BY 
    rn.region_total_value DESC, nation_count DESC;
