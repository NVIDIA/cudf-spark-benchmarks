WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) as rank
    FROM 
        part p
    WHERE 
        p.p_type LIKE 'ELECTRONICS%'
),
SupplierCounts AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey
),
EnhancedParts AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_mfgr,
        rp.p_brand,
        rp.p_type,
        rp.p_retailprice,
        rp.p_comment,
        sc.supplier_count,
        CONCAT(rp.p_name, ' | ', rp.p_brand, ' | ', rp.p_comment) AS description
    FROM 
        RankedParts rp
    JOIN 
        SupplierCounts sc ON rp.p_partkey = sc.ps_partkey
    WHERE 
        rp.rank <= 5
)
SELECT 
    ep.p_partkey,
    ep.p_name,
    ep.p_mfgr,
    ep.p_brand,
    ep.p_type,
    ep.p_retailprice,
    ep.supplier_count,
    ep.description
FROM 
    EnhancedParts ep
ORDER BY 
    ep.p_retailprice DESC,
    ep.supplier_count DESC;
