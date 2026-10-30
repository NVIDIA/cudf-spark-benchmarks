WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        RANK() OVER (ORDER BY total_supplycost DESC) AS rank
    FROM 
        RankedSuppliers s
)
SELECT 
    c.c_custkey, 
    c.c_name, 
    o.o_orderkey, 
    o.o_totalprice, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue, 
    ns.n_name AS nation
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    nation ns ON s.s_nationkey = ns.n_nationkey
JOIN 
    TopSuppliers ts ON s.s_suppkey = ts.s_suppkey
WHERE 
    o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
    AND l.l_shipdate < o.o_orderdate
GROUP BY 
    c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice, ns.n_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    revenue DESC
LIMIT 20;