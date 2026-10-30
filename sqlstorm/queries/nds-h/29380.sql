
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        r.r_name AS region_name,
        COUNT(DISTINCT ps.ps_partkey) AS num_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        ROW_NUMBER() OVER (PARTITION BY r.r_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS ranking
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, r.r_regionkey, r.r_name
),
TopRanked AS (
    SELECT 
        rs.region_name,
        MIN(rs.ranking) AS top_ranking
    FROM 
        RankedSuppliers rs
    GROUP BY 
        rs.region_name
)
SELECT 
    rs.s_suppkey,
    rs.s_name,
    rs.total_supply_value,
    rt.region_name
FROM 
    RankedSuppliers rs
JOIN 
    TopRanked rt ON rs.ranking = rt.top_ranking
ORDER BY 
    rt.region_name, rs.total_supply_value DESC;
