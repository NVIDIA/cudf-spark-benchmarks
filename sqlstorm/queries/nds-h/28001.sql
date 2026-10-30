WITH PartStats AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        CONCAT(p.p_mfgr, ' | ', p.p_brand, ' | ', p.p_type) AS part_info,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        r.r_name AS region_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, r.r_name
)
SELECT 
    ps.part_info,
    ps.supplier_count,
    ps.total_available_qty,
    ps.avg_supply_cost,
    si.s_name,
    si.region_name,
    si.part_count,
    si.total_cost
FROM 
    PartStats ps
JOIN 
    SupplierInfo si ON ps.p_partkey = si.part_count
WHERE 
    ps.total_available_qty > 100
ORDER BY 
    ps.avg_supply_cost DESC, si.part_count DESC;
