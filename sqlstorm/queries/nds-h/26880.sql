WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_type,
        LENGTH(p.p_name) AS name_length,
        TRIM(p.p_comment) AS trimmed_comment,
        CONCAT(p.p_brand, ' - ', p.p_container) AS brand_container
    FROM 
        part p
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        SUBSTR(s.s_comment, 1, 50) AS short_comment,
        n.n_name AS nation_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
PartSupplierMetrics AS (
    SELECT 
        ps.ps_partkey,
        COUNT(*) AS supplier_count,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS average_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.name_length,
    rp.trimmed_comment,
    rp.brand_container,
    sd.supply_count,
    ps.total_available_qty,
    ps.average_supply_cost
FROM 
    RankedParts rp
LEFT JOIN 
    (SELECT ps.ps_partkey, COUNT(DISTINCT ps.ps_suppkey) AS supply_count FROM partsupp ps GROUP BY ps.ps_partkey) sd ON rp.p_partkey = sd.ps_partkey
LEFT JOIN 
    PartSupplierMetrics ps ON rp.p_partkey = ps.ps_partkey
WHERE 
    rp.name_length > 10
ORDER BY 
    rp.name_length DESC, 
    ps.total_available_qty ASC;
