WITH StringAnalytics AS (
    SELECT 
        p_name, 
        LENGTH(p_name) AS name_length, 
        UPPER(p_name) AS uppercased_name, 
        LOWER(p_name) AS lowercased_name, 
        REPLACE(p_name, 'a', '@') AS name_replaced,
        CASE 
            WHEN p_name LIKE '%special%' THEN 'Contains Special'
            ELSE 'Regular'
        END AS name_type
    FROM 
        part
),
RegionSupplier AS (
    SELECT 
        r.r_name AS region_name,
        s.s_name AS supplier_name,
        CONCAT(s.s_name, ' located in ', r.r_name) AS supplier_location
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
)
SELECT 
    sa.p_name,
    sa.name_length,
    sa.uppercased_name,
    sa.lowercased_name,
    sa.name_replaced,
    sa.name_type,
    rs.region_name,
    rs.supplier_location
FROM 
    StringAnalytics sa
JOIN 
    RegionSupplier rs ON sa.name_type = 'Contains Special'
ORDER BY 
    sa.name_length DESC, 
    rs.region_name ASC;
