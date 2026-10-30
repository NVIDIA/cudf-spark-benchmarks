WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        TRIM(UPPER(p.p_comment)) AS normalized_comment
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_size, p.p_comment
),
FilteredParts AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_mfgr,
        rp.p_brand,
        rp.p_type,
        rp.p_size,
        rp.supplier_count,
        rp.total_avail_qty,
        rp.total_supply_cost,
        rp.normalized_comment,
        RANK() OVER (PARTITION BY rp.p_mfgr ORDER BY rp.total_supply_cost DESC) AS mfg_rank
    FROM 
        RankedParts rp
    WHERE 
        rp.total_avail_qty > 0
)
SELECT 
    fp.p_partkey,
    fp.p_name,
    fp.p_mfgr,
    fp.p_brand,
    fp.p_type,
    fp.p_size,
    fp.supplier_count,
    fp.total_avail_qty,
    fp.total_supply_cost,
    fp.normalized_comment
FROM 
    FilteredParts fp
WHERE 
    fp.mfg_rank <= 5
ORDER BY 
    fp.p_mfgr, fp.total_supply_cost DESC;
