
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
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
        rs.s_suppkey, 
        rs.s_name, 
        rs.nation_name,
        rs.total_supply_value,
        rs.rank
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rank <= 5
)
SELECT 
    c.c_custkey, 
    c.c_name, 
    c.c_acctbal, 
    o.o_orderkey, 
    o.o_orderdate, 
    o.o_totalprice,
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
    o.o_orderdate >= DATE '1997-01-01' AND 
    o.o_orderdate < DATE '1997-10-01'
ORDER BY 
    c.c_custkey, o.o_orderdate;
