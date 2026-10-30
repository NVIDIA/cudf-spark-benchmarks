WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rnk,
        n.n_name AS nation_name
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_name
),
TopSuppliers AS (
    SELECT 
        nation_name, 
        s_suppkey, 
        s_name, 
        total_supply_cost 
    FROM 
        RankedSuppliers 
    WHERE 
        rnk <= 3
)
SELECT 
    r.r_name AS region_name, 
    ts.nation_name, 
    ARRAY_AGG(ts.s_name) AS top_supplier_names, 
    SUM(ts.total_supply_cost) AS total_cost
FROM 
    TopSuppliers ts
JOIN 
    nation n ON ts.nation_name = n.n_name
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
GROUP BY 
    r.r_name, ts.nation_name
ORDER BY 
    total_cost DESC;
