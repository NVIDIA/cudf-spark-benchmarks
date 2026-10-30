WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
NationDetails AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name,
        n.n_comment
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    nd.region_name,
    nd.n_name AS nation_name,
    rs.s_name AS supplier_name,
    rs.total_supply_value
FROM 
    RankedSuppliers rs
JOIN 
    NationDetails nd ON rs.s_nationkey = nd.n_nationkey
WHERE 
    rs.rnk <= 3
ORDER BY 
    nd.region_name, rs.total_supply_value DESC;
