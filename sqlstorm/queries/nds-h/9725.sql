WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        s.s_nationkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
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
        n.n_name AS nation_name, 
        rs.s_suppkey, 
        rs.s_name, 
        rs.total_supply_cost,
        RANK() OVER (PARTITION BY n.n_nationkey ORDER BY rs.total_supply_cost DESC) AS supplier_rank
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    ts.region_name, 
    ts.nation_name, 
    ts.s_name, 
    ts.total_supply_cost
FROM 
    TopSuppliers ts
WHERE 
    ts.supplier_rank <= 5
ORDER BY 
    ts.region_name, 
    ts.nation_name, 
    ts.total_supply_cost DESC;
