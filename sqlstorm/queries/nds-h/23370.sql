
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rank_per_region
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        COALESCE(p.p_brand, 'Unknown Brand') AS formatted_brand,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice, p.p_brand
)
SELECT 
    fp.p_partkey,
    fp.p_name,
    fp.p_retailprice,
    fp.formatted_brand,
    CONCAT('This part is supplied by ', COALESCE(fp.supplier_count, 0), ' suppliers.') AS supplier_info,
    CASE 
        WHEN fp.supplier_count > 5 THEN 'Widely Available'
        ELSE 'Limited Availability'
    END AS availability_status,
    s.s_name AS top_supplier
FROM 
    FilteredParts fp
LEFT JOIN 
    RankedSuppliers s ON s.rank_per_region = 1 AND s.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey = fp.p_partkey
    )
WHERE 
    (fp.p_retailprice BETWEEN 50.00 AND 100.00 OR fp.p_retailprice IS NULL)
    AND (fp.p_name LIKE '%gen%' OR fp.formatted_brand = 'Unknown Brand')
ORDER BY 
    availability_status DESC, 
    fp.p_retailprice;
