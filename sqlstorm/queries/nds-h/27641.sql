WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        SUM(CASE 
            WHEN LENGTH(p.p_name) > 20 THEN 1 
            ELSE 0 
        END) AS long_name_count
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_size, p.p_container, p.p_retailprice, p.p_comment
),
FilteredProducts AS (
    SELECT 
        r.r_name AS region_name,
        np.n_name AS nation_name,
        p.p_name AS part_name,
        p.supplier_count,
        p.long_name_count
    FROM 
        RankedParts p
    JOIN 
        supplier s ON p.p_partkey = s.s_suppkey
    JOIN 
        nation np ON s.s_nationkey = np.n_nationkey
    JOIN 
        region r ON np.n_regionkey = r.r_regionkey
    WHERE 
        p.long_name_count > 0
)
SELECT 
    region_name,
    nation_name,
    COUNT(part_name) AS product_count,
    SUM(supplier_count) AS total_suppliers
FROM 
    FilteredProducts
GROUP BY 
    region_name, nation_name
ORDER BY 
    region_name, nation_name;
