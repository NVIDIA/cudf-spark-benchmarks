WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_mfgr, 
        p.p_brand, 
        p.p_type,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY LENGTH(p.p_name) DESC) AS rank_name_length,
        COUNT(*) OVER (PARTITION BY p.p_brand) AS brand_count
    FROM 
        part p
),
FilteredParts AS (
    SELECT 
        rp.p_partkey, 
        rp.p_name, 
        rp.p_mfgr, 
        rp.p_brand, 
        rp.p_type
    FROM 
        RankedParts rp
    WHERE 
        rp.rank_name_length <= 5 AND rp.brand_count > 10
),
SupplierPartCounts AS (
    SELECT 
        ps.ps_partkey, 
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    JOIN 
        FilteredParts fp ON ps.ps_partkey = fp.p_partkey
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    fp.p_partkey, 
    fp.p_name, 
    spc.supplier_count,
    fp.p_mfgr, 
    fp.p_brand, 
    fp.p_type
FROM 
    FilteredParts fp
JOIN 
    SupplierPartCounts spc ON fp.p_partkey = spc.ps_partkey
ORDER BY 
    spc.supplier_count DESC, 
    LENGTH(fp.p_name) ASC
LIMIT 10;
