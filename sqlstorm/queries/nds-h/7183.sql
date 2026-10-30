
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS supplier_nation,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supply_rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, n.n_regionkey
),
TopSuppliers AS (
    SELECT 
        supplier_nation,
        s_name,
        total_supply_value,
        s_suppkey
    FROM 
        RankedSuppliers
    WHERE 
        supply_rank <= 5
)
SELECT 
    c.c_name AS customer_name,
    o.o_orderkey,
    o.o_orderdate,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
    ts.supplier_nation,
    ts.s_name AS top_supplier,
    COUNT(DISTINCT l.l_orderkey) AS lineitem_count
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    TopSuppliers ts ON l.l_suppkey = ts.s_suppkey
WHERE 
    o.o_orderdate >= '1996-01-01' AND o.o_orderdate < '1997-01-01'
GROUP BY 
    c.c_name, o.o_orderkey, o.o_orderdate, ts.supplier_nation, ts.s_name
ORDER BY 
    total_order_value DESC
LIMIT 100;
