
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
CustomerPurchases AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    p.p_name,
    r.r_name,
    cs.c_name AS customer_name,
    cs.total_spent,
    ss.total_available,
    ss.avg_supply_cost,
    COUNT(DISTINCT lo.o_orderkey) AS total_orders,
    SUM(lo.o_totalprice) AS total_order_value
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    region r ON s.s_nationkey = r.r_regionkey
LEFT JOIN 
    CustomerPurchases cs ON s.s_nationkey = cs.c_custkey
LEFT JOIN 
    RankedOrders lo ON lo.o_orderkey = ps.ps_partkey
LEFT JOIN 
    SupplierStats ss ON s.s_suppkey = ss.s_suppkey
WHERE 
    p.p_retailprice > (
        SELECT AVG(p2.p_retailprice) FROM part p2
    )
    AND ss.avg_supply_cost < (SELECT AVG(ps2.ps_supplycost) FROM partsupp ps2)
GROUP BY 
    p.p_name, r.r_name, cs.c_name, cs.total_spent, ss.total_available, ss.avg_supply_cost
ORDER BY 
    total_orders DESC, total_order_value DESC;
