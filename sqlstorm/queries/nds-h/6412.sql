WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
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
        s.nation_name,
        RANK() OVER (PARTITION BY nation_name ORDER BY total_supply_value DESC) AS supplier_rank
    FROM 
        RankedSuppliers s
)
SELECT 
    c.c_custkey,
    c.c_name,
    c.c_address,
    c.c_phone,
    sum(o.o_totalprice) AS total_order_value,
    ts.nation_name
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    TopSuppliers ts ON l.l_suppkey = ts.s_suppkey
WHERE 
    ts.supplier_rank <= 5
GROUP BY 
    c.c_custkey, c.c_name, c.c_address, c.c_phone, ts.nation_name
ORDER BY 
    total_order_value DESC;
