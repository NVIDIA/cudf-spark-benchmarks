
WITH SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
RegionNations AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY 
        r.r_regionkey, r.r_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        sp.part_count,
        sp.total_supply_cost,
        RANK() OVER (ORDER BY sp.total_supply_cost DESC) AS rnk
    FROM 
        SupplierParts sp
    JOIN 
        supplier s ON sp.s_suppkey = s.s_suppkey
)
SELECT 
    rn.r_name,
    ts.s_name,
    ts.part_count,
    ts.total_supply_cost,
    rn.nation_count
FROM 
    TopSuppliers ts
JOIN 
    nation n ON ts.s_suppkey = n.n_nationkey
JOIN 
    RegionNations rn ON n.n_regionkey = rn.r_regionkey
WHERE 
    ts.rnk <= 10
ORDER BY 
    ts.total_supply_cost DESC, rn.r_name ASC;
