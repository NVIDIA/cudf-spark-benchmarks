WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1997-01-01' AND 
        o.o_orderdate < '1997-12-31'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        SUM(ps.ps_availqty) AS total_available_quantity, 
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
CustomerOrderInfo AS (
    SELECT 
        c.c_custkey, 
        COUNT(DISTINCT o.o_orderkey) AS order_count, 
        MAX(o.o_totalprice) AS max_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 100.00
    GROUP BY 
        c.c_custkey
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    COALESCE(c.order_count, 0) AS customer_order_count,
    COALESCE(c.max_order_value, 0) AS customer_max_order_value,
    s.total_available_quantity,
    s.avg_supply_cost
FROM 
    RankedOrders r
LEFT JOIN 
    CustomerOrderInfo c ON r.o_orderkey = c.c_custkey
LEFT JOIN 
    SupplierStats s ON r.o_orderkey = s.s_suppkey
WHERE 
    r.rn <= 10 
ORDER BY 
    r.o_orderdate DESC,
    r.o_totalprice DESC;