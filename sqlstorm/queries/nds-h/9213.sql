WITH SupplierProfit AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
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
        SupplierProfit sp
    JOIN 
        supplier s ON sp.s_suppkey = s.s_suppkey
    WHERE 
        sp.profit > (SELECT AVG(profit) FROM SupplierProfit)
    ORDER BY 
        sp.profit DESC
    LIMIT 10
)
SELECT 
    ts.s_name,
    ts.profit,
    r.r_name,
    n.n_name
FROM 
    TopSuppliers ts
JOIN 
    supplier s ON ts.s_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey;
