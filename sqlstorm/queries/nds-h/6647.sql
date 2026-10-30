WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        s.total_cost,
        RANK() OVER (ORDER BY s.total_cost DESC) AS rnk
    FROM 
        RankedSuppliers s
)
SELECT 
    c.c_custkey, 
    c.c_name, 
    o.o_orderkey, 
    o.o_orderdate, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    ts.s_name AS top_supplier
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    TopSuppliers ts ON ts.s_suppkey = l.l_suppkey
WHERE 
    o.o_orderdate >= DATE '1996-01-01'
    AND o.o_orderdate < DATE '1996-12-31'
GROUP BY 
    c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, ts.s_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    revenue DESC
LIMIT 10;