WITH RankedParts AS (
    SELECT 
        p_name, 
        p_mfgr, 
        p_brand, 
        p_type, 
        COUNT(ps.ps_partkey) AS supplier_count,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY p_brand ORDER BY SUM(ps.ps_availqty) DESC) AS rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p_name, p_mfgr, p_brand, p_type
), FilteredParts AS (
    SELECT 
        p.*,
        rp.supplier_count,
        rp.total_avail_qty,
        rp.total_supply_cost
    FROM 
        RankedParts rp
    JOIN 
        part p ON rp.p_name = p.p_name 
    WHERE 
        rp.rank <= 5
)
SELECT 
    fp.p_name, 
    fp.p_mfgr, 
    fp.p_brand, 
    fp.p_type,
    fp.supplier_count,
    fp.total_avail_qty,
    fp.total_supply_cost,
    CONCAT(fp.p_name, ' - ', fp.p_mfgr) AS combined_info
FROM 
    FilteredParts fp
WHERE 
    fp.total_supply_cost > (SELECT AVG(total_supply_cost) FROM RankedParts);
