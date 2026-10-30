WITH PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        CONCAT(p.p_name, ' | ', p.p_mfgr, ' | ', p.p_brand) AS part_description,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_brand
),
RegionWiseSupplier AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        s.s_name AS supplier_name,
        COUNT(DISTINCT p.p_partkey) AS parts_supplied
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        r.r_name, n.n_name, s.s_name
)
SELECT 
    pd.part_description,
    pd.total_available_quantity,
    pd.avg_supply_cost,
    rws.region_name,
    rws.nation_name,
    rws.supplier_name,
    rws.parts_supplied
FROM 
    PartDetails pd
JOIN 
    RegionWiseSupplier rws ON pd.p_partkey IN (
        SELECT ps.ps_partkey
        FROM partsupp ps
        JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
        JOIN nation n ON s.s_nationkey = n.n_nationkey
        JOIN region r ON n.n_regionkey = r.r_regionkey
        WHERE r.r_name LIKE 'Asia%'
    )
ORDER BY 
    pd.avg_supply_cost DESC, pd.total_available_quantity DESC;
