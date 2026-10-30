WITH SupplierProfitability AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        (SUM(l.l_extendedprice * (1 - l.l_discount)) - SUM(ps.ps_supplycost * ps.ps_availqty)) AS profit
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        sp.profit
    FROM 
        SupplierProfitability sp
    JOIN 
        supplier s ON sp.s_suppkey = s.s_suppkey
    ORDER BY 
        sp.profit DESC
    LIMIT 10
)
SELECT 
    c.c_name,
    SUM(o.o_totalprice) AS total_orders,
    ts.s_name,
    ts.profit
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    TopSuppliers ts ON ps.ps_suppkey = ts.s_suppkey
GROUP BY 
    c.c_name, ts.s_name, ts.profit
HAVING 
    SUM(o.o_totalprice) > 10000
ORDER BY 
    total_orders DESC, ts.profit DESC;
