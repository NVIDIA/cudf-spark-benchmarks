WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        c.c_custkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS price_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
),
FilteredSuppliers AS (
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
        SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    no.c_custkey,
    no.total_orders,
    no.total_spent,
    ro.o_orderkey,
    ro.o_orderdate,
    ro.price_rank,
    fs.s_name,
    fs.total_supply_cost
FROM 
    CustomerOrders no
JOIN 
    RankedOrders ro ON no.c_custkey = ro.c_custkey
LEFT JOIN 
    FilteredSuppliers fs ON fs.total_supply_cost < no.total_spent
WHERE 
    ro.price_rank = 1 
    AND fs.s_name IS NULL
ORDER BY 
    no.total_spent DESC, ro.o_orderdate ASC;
