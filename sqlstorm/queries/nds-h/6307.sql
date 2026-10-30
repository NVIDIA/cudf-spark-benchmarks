
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost) DESC) AS supplier_rank,
        s.s_nationkey
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        r.r_name AS region_name,
        ns.n_name AS nation_name,
        rs.s_suppkey,
        rs.s_name,
        rs.total_supply_cost,
        rs.part_count
    FROM 
        RankedSuppliers rs
    JOIN 
        nation ns ON rs.s_nationkey = ns.n_nationkey
    JOIN 
        region r ON ns.n_regionkey = r.r_regionkey
    WHERE 
        rs.supplier_rank <= 5
)
SELECT 
    region_name,
    nation_name,
    SUM(total_supply_cost) AS region_total_supply_cost,
    SUM(part_count) AS total_parts_supplied
FROM 
    TopSuppliers
GROUP BY 
    region_name, nation_name
ORDER BY 
    region_total_supply_cost DESC, nation_name ASC;
