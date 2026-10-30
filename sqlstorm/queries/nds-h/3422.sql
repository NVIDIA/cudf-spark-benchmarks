
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    COALESCE(SP.total_available_quantity, 0) AS total_available_quantity,
    COALESCE(SP.avg_supply_cost, 0) AS avg_supply_cost,
    COALESCE(CU.total_orders, 0) AS total_orders,
    CU.total_spent
FROM 
    RankedOrders r
LEFT JOIN 
    SupplierParts SP ON r.o_orderkey = SP.ps_partkey
LEFT JOIN 
    CustomerOrders CU ON CU.total_orders > 0
WHERE 
    r.order_rank <= 10
UNION ALL
SELECT 
    NULL AS o_orderkey,
    NULL AS o_orderdate,
    NULL AS o_totalprice,
    SUM(SP.total_available_quantity) AS total_available_quantity,
    AVG(SP.avg_supply_cost) AS avg_supply_cost,
    COUNT(CU.total_orders) AS total_orders,
    SUM(CU.total_spent) AS total_spent
FROM 
    SupplierParts SP
JOIN 
    CustomerOrders CU ON CU.total_orders = 0
WHERE 
    SP.avg_supply_cost < 100
GROUP BY 
    SP.ps_partkey
HAVING 
    COUNT(*) > 1
ORDER BY 
    total_available_quantity DESC;
