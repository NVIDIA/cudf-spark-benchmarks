
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        CONCAT(p.p_name, ' by ', p.p_mfgr) AS full_description,
        STRING_AGG(DISTINCT CAST(ps.ps_supplycost AS STRING), ', ') AS supplier_costs,
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY AVG(ps.ps_supplycost) DESC) AS rn
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr
),
FilteredParts AS (
    SELECT 
        rp.p_partkey,
        rp.full_description,
        rp.supplier_costs
    FROM 
        RankedParts rp
    WHERE 
        rp.rn <= 3
)
SELECT 
    fp.full_description,
    fp.supplier_costs,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(l.l_quantity) AS total_quantity,
    ROUND(SUM(l.l_extendedprice * (1 - l.l_discount)), 2) AS total_revenue
FROM 
    FilteredParts fp
LEFT JOIN 
    lineitem l ON l.l_partkey = fp.p_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
GROUP BY 
    fp.full_description, fp.supplier_costs
ORDER BY 
    total_revenue DESC
LIMIT 10;
