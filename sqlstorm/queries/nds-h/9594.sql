WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank_within_nation
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, n.n_regionkey
),
TopSuppliers AS (
    SELECT 
        r.r_name AS region_name,
        AVG(rs.total_supply_cost) AS avg_supply_cost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.nation = n.n_name
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.rank_within_nation <= 3
    GROUP BY 
        r.r_name
)
SELECT 
    ts.region_name,
    ts.avg_supply_cost
FROM 
    TopSuppliers ts
ORDER BY 
    ts.avg_supply_cost DESC;
