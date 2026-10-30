WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_clerk,
        ROW_NUMBER() OVER (PARTITION BY o.o_clerk ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'F'
),
HighValueSuppliers AS (
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
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 100000
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey 
    WHERE 
        o.o_orderkey IS NOT NULL
)
SELECT 
    co.c_name,
    co.o_orderdate,
    co.o_totalprice,
    rs.p_name,
    rs.total_supply_cost
FROM 
    CustomerOrders co
JOIN 
    (SELECT 
         p.p_name,
         ps.ps_partkey,
         SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
     FROM 
         part p
     JOIN 
         partsupp ps ON p.p_partkey = ps.ps_partkey
     GROUP BY 
         p.p_name, ps.ps_partkey) rs ON co.o_orderkey = rs.ps_partkey
LEFT JOIN 
    RankedOrders ro ON co.o_orderkey = ro.o_orderkey
WHERE 
    ro.order_rank <= 3
AND 
    co.o_totalprice > (SELECT AVG(o_totalprice) FROM orders)
ORDER BY 
    co.o_orderdate DESC, 
    co.c_name ASC;

