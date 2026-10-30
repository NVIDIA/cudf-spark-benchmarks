WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        COUNT(p.ps_partkey) AS parts_count,
        SUM(p.ps_supplycost * p.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp p ON s.s_suppkey = p.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
TopSuppliers AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY nation_name ORDER BY total_supply_cost DESC) AS rank
    FROM 
        RankedSuppliers
)
SELECT 
    ts.s_suppkey,
    ts.s_name,
    ts.nation_name,
    ts.parts_count,
    ts.total_supply_cost
FROM 
    TopSuppliers ts
WHERE 
    ts.rank = 1
ORDER BY 
    ts.nation_name, ts.total_supply_cost DESC;
