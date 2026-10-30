
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
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
        ts.nation_name,
        ts.s_suppkey,
        ts.s_name,
        ts.total_cost
    FROM 
        RankedSuppliers ts
    WHERE 
        ts.rank = 1
)
SELECT 
    c.c_custkey,
    c.c_name,
    o.o_orderkey,
    o.o_orderdate,
    li.l_partkey,
    li.l_quantity,
    ts.nation_name,
    ts.total_cost
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem li ON o.o_orderkey = li.l_orderkey
JOIN 
    TopSuppliers ts ON li.l_suppkey = ts.s_suppkey
WHERE 
    o.o_orderdate >= DATE '1997-01-01' 
    AND o.o_orderdate <= DATE '1997-12-31'
ORDER BY 
    ts.nation_name, o.o_orderdate DESC, li.l_quantity DESC;
