
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
), 
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    C.c_name,
    SUM(C.total_spent) AS total_spent,
    AVG(C.order_count) AS avg_orders,
    S.s_name,
    SUM(S.total_supply_cost) AS total_supply_cost
FROM 
    CustomerStats C 
LEFT JOIN 
    SupplierDetails S ON C.c_custkey % 10 = S.s_nationkey
WHERE 
    C.last_order_date >= CURRENT_DATE - INTERVAL '6 MONTH'
GROUP BY 
    C.c_name, S.s_name
HAVING 
    SUM(C.total_spent) > 1000
ORDER BY 
    total_spent DESC;
