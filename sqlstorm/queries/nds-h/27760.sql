WITH StringProcessed AS (
    SELECT 
        p.p_partkey,
        CONCAT(
            'Part: ',
            p.p_name,
            ' | Manufacturer: ',
            p.p_mfgr,
            ' | Brand: ',
            p.p_brand,
            ' | Type: ',
            p.p_type,
            ' | Size: ',
            CAST(p.p_size AS STRING),
            ' | Retail Price: $',
            CAST(p.p_retailprice AS STRING),
            ' | Comment: ',
            p.p_comment
        ) AS processed_string
    FROM 
        part p
),
RegionSupplier AS (
    SELECT 
        r.r_name AS region_name,
        s.s_name AS supplier_name,
        s.s_address AS supplier_address
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
CombinedData AS (
    SELECT 
        sp.processed_string,
        rs.region_name,
        rs.supplier_name,
        rs.supplier_address
    FROM 
        StringProcessed sp
    CROSS JOIN 
        RegionSupplier rs
)
SELECT 
    processed_string,
    region_name,
    supplier_name,
    supplier_address
FROM 
    CombinedData
WHERE 
    region_name LIKE '%West%'
ORDER BY 
    supplier_name, 
    processed_string;
