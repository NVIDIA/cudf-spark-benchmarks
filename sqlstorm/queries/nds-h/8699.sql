WITH SupplierAggregates AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value
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
        s.nation_name,
        total_value,
        RANK() OVER (ORDER BY total_value DESC) AS rank
    FROM 
        SupplierAggregates s
)
SELECT 
    o.o_orderkey,
    c.c_name,
    l.l_quantity,
    l.l_extendedprice,
    l.l_discount,
    ts.s_name AS supplier_name,
    ts.nation_name,
    o.o_orderdate
FROM 
    orders o
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    TopSuppliers ts ON l.l_suppkey = ts.s_suppkey
WHERE 
    o.o_orderdate >= DATE '1997-01-01' 
    AND o.o_orderdate < DATE '1997-12-31'
    AND ts.rank <= 10
ORDER BY 
    total_value DESC, o.o_orderdate DESC;