WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY r.r_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, r.r_regionkey
),
TopSuppliers AS (
    SELECT 
        r.r_name,
        rs.s_suppkey,
        rs.s_name,
        rs.total_cost
    FROM 
        RankedSuppliers rs
    JOIN 
        region r ON rs.rank <= 5
)
SELECT 
    ts.r_name,
    COUNT(DISTINCT ts.s_suppkey) AS num_suppliers,
    SUM(ts.total_cost) AS total_supply_cost
FROM 
    TopSuppliers ts
GROUP BY 
    ts.r_name
ORDER BY 
    total_supply_cost DESC;
