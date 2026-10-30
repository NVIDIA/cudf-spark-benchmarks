WITH SupplierPartDetails AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        SUBSTRING(p.p_comment FROM 1 FOR 20) AS short_comment,
        CONCAT('Region: ', r.r_name, ', Nation: ', n.n_name) AS location_info,
        SUM(ps.ps_availqty) AS total_available_qty
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        s.s_name, p.p_name, p.p_comment, r.r_name, n.n_name
)
SELECT 
    supplier_name, 
    part_name, 
    short_comment, 
    location_info,
    total_available_qty
FROM 
    SupplierPartDetails
WHERE 
    total_available_qty > 50
ORDER BY 
    location_info, part_name;
