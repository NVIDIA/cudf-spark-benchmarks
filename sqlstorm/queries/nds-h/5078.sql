WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation,
        COUNT(DISTINCT ps.ps_partkey) AS distinct_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
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
        s.s_suppkey,
        s.s_name,
        s.nation,
        s.distinct_parts,
        s.total_cost,
        ROW_NUMBER() OVER (PARTITION BY s.nation ORDER BY s.total_cost DESC) AS rn
    FROM 
        RankedSuppliers s
)
SELECT 
    ts.s_suppkey,
    ts.s_name,
    ts.total_cost,
    o.o_orderkey,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
FROM 
    TopSuppliers ts
JOIN 
    lineitem l ON ts.s_suppkey = l.l_suppkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    ts.rn <= 3 AND
    o.o_orderdate >= DATE '1997-01-01' AND 
    o.o_orderdate <= DATE '1997-12-31'
GROUP BY 
    ts.s_suppkey, ts.s_name, ts.total_cost, o.o_orderkey
ORDER BY 
    ts.total_cost DESC, revenue DESC;