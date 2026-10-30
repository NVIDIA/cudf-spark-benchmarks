WITH RankedCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rank_within_nation
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_nationkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    ORDER BY 
        total_supply_cost DESC
    LIMIT 10
)
SELECT 
    rc.c_name AS Customer_Name,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
    ts.s_name AS Supplier_Name,
    MAX(rc.rank_within_nation) AS Highest_Rank_Nation,
    COUNT(DISTINCT o.o_orderkey) AS order_count
FROM 
    lineitem li
JOIN 
    orders o ON li.l_orderkey = o.o_orderkey
JOIN 
    RankedCustomers rc ON o.o_custkey = rc.c_custkey
JOIN 
    TopSuppliers ts ON li.l_suppkey = ts.s_suppkey
WHERE 
    li.l_shipdate >= '1995-01-01' AND li.l_shipdate < '1996-01-01'
GROUP BY 
    rc.c_name, ts.s_name
HAVING 
    SUM(li.l_extendedprice * (1 - li.l_discount)) > 10000
ORDER BY 
    total_revenue DESC;