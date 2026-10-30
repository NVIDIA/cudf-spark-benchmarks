WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name,
        COUNT(DISTINCT ps.ps_partkey) AS parts_supplied,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
TopSuppliers AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY n_name ORDER BY total_supply_cost DESC) AS rank
    FROM 
        RankedSuppliers
)
SELECT 
    r.r_name AS region,
    ts.s_name AS supplier,
    ts.parts_supplied,
    ts.total_supply_cost
FROM 
    TopSuppliers ts
JOIN 
    nation n ON ts.n_name = n.n_name
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    ts.rank <= 5
ORDER BY 
    r.r_name, ts.total_supply_cost DESC;
