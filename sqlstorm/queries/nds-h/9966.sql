
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),

CustomerOrderSummary AS (
    SELECT 
        c.c_custkey, 
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= '1997-01-01'
    GROUP BY 
        c.c_custkey, c.c_name
)

SELECT 
    r.n_name AS r_name, 
    rs.s_name, 
    cos.c_name, 
    cos.total_spent, 
    cos.order_count, 
    rs.total_supply_cost
FROM 
    RankedSuppliers rs
JOIN 
    nation r ON rs.s_nationkey = r.n_nationkey
JOIN 
    CustomerOrderSummary cos ON cos.total_spent > (SELECT AVG(total_spent) FROM CustomerOrderSummary)
WHERE 
    rs.rnk <= 10
ORDER BY 
    r.n_name, rs.total_supply_cost DESC;
