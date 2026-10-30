WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_partkey
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey, 
        rs.s_name, 
        rs.total_cost
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.supplier_rank <= 5
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
    TopSuppliers ts ON l.l_suppkey = ts.s_suppkey
WHERE 
    o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
GROUP BY 
    c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, ts.s_name
ORDER BY 
    revenue DESC
LIMIT 10;