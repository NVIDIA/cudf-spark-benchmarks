
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
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
        supplier_rank,
        s_suppkey,
        s_name,
        nation_name
    FROM 
        RankedSuppliers
    WHERE 
        supplier_rank <= 5
)
SELECT 
    c.c_custkey,
    c.c_name,
    c.c_nationkey,
    SUM(o.o_totalprice) AS total_spent,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    ts.s_name AS top_supplier
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    TopSuppliers ts ON l.l_suppkey = ts.s_suppkey
GROUP BY 
    c.c_custkey, c.c_name, c.c_nationkey, ts.s_name
HAVING 
    SUM(o.o_totalprice) > 100000
ORDER BY 
    total_spent DESC
LIMIT 10;
