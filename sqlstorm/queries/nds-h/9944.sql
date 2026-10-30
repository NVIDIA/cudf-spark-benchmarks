
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        n.n_name AS nation_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, n.n_nationkey
),
TopSuppliers AS (
    SELECT 
        nation_name, 
        s_suppkey, 
        s_name, 
        total_cost
    FROM 
        RankedSuppliers 
    WHERE 
        rank <= 5
)
SELECT 
    p.p_partkey, 
    p.p_name, 
    ts.nation_name, 
    ts.total_cost
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    TopSuppliers ts ON ps.ps_suppkey = ts.s_suppkey
WHERE 
    p.p_size > 10
ORDER BY 
    ts.nation_name, ts.total_cost DESC;
