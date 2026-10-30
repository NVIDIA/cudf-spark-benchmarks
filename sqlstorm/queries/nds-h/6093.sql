
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn,
        n.n_regionkey
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_regionkey
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.total_supply_cost,
        n.n_name AS region_name
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.n_regionkey = n.n_nationkey
    WHERE 
        rs.rn <= 5
)
SELECT 
    c.c_custkey,
    c.c_name,
    c.c_acctbal,
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice,
    ts.s_name,
    ts.total_supply_cost,
    ts.region_name
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    TopSuppliers ts ON l.l_suppkey = ts.s_suppkey
WHERE 
    o.o_orderstatus = 'O'
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
ORDER BY 
    ts.total_supply_cost DESC,
    o.o_orderdate DESC;
