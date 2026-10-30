WITH PartDetails AS (
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
        LENGTH(p.p_name) AS name_length,
        LENGTH(p.p_comment) AS comment_length,
        CONCAT(p.p_brand, ' - ', p.p_type) AS brand_type
    FROM 
        part p
),
SupplierCount AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
TotalSales AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    GROUP BY 
        l.l_partkey
)
SELECT 
    pd.p_partkey,
    pd.p_name,
    pd.brand_type,
    SC.supplier_count,
    COALESCE(TS.total_sales, 0) AS total_sales,
    pd.name_length,
    pd.comment_length
FROM 
    PartDetails pd
LEFT JOIN 
    SupplierCount SC ON pd.p_partkey = SC.ps_partkey
LEFT JOIN 
    TotalSales TS ON pd.p_partkey = TS.l_partkey
WHERE 
    pd.p_retailprice > 20.00
ORDER BY 
    total_sales DESC, 
    pd.name_length DESC;
