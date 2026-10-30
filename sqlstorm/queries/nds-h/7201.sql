WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
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
        s.total_parts,
        s.total_supply_value,
        DENSE_RANK() OVER (ORDER BY s.total_supply_value DESC) AS supplier_rank
    FROM 
        SupplierSummary s
    WHERE 
        s.total_parts > 5
)
SELECT 
    c.c_custkey,
    c.c_name,
    o.o_orderkey,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    ts.s_name AS top_supplier,
    ts.nation AS supplier_nation
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    TopSuppliers ts ON l.l_suppkey = ts.s_suppkey
WHERE 
    o.o_orderdate >= DATE '1997-01-01' 
    AND o.o_orderdate < DATE '1998-01-01'
GROUP BY 
    c.c_custkey, c.c_name, o.o_orderkey, ts.s_name, ts.nation
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
ORDER BY 
    revenue DESC;