WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighCostSuppliers AS (
    SELECT 
        r.r_name, 
        n.n_name, 
        rs.s_suppkey, 
        rs.s_name, 
        rs.total_supply_cost
    FROM 
        RankedSuppliers rs
    JOIN 
        supplier s ON rs.s_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.rank <= 10
)
SELECT 
    hs.r_name AS region, 
    hs.n_name AS nation, 
    COUNT(hs.s_suppkey) AS supplier_count, 
    SUM(hs.total_supply_cost) AS total_cost
FROM 
    HighCostSuppliers hs
GROUP BY 
    hs.r_name, hs.n_name
ORDER BY 
    total_cost DESC, supplier_count DESC;
