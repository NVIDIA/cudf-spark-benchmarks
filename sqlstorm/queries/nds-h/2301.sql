
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        o.o_custkey,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1997-01-01'
), SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
), CustomerRegion AS (
    SELECT 
        c.c_custkey,
        n.n_nationkey,
        r.r_regionkey,
        r.r_name
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        c.c_acctbal > 1000
)
SELECT 
    cr.r_name AS region_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(o.o_totalprice) AS average_order_value,
    SUM(lp.l_extendedprice * (1 - lp.l_discount)) AS total_revenue,
    SUM(sp.total_supply_cost) AS total_supply_cost
FROM 
    RankedOrders o
LEFT JOIN 
    lineitem lp ON o.o_orderkey = lp.l_orderkey
JOIN 
    CustomerRegion cr ON o.o_custkey = cr.c_custkey
LEFT JOIN 
    SupplierParts sp ON lp.l_partkey = sp.ps_partkey
WHERE 
    o.o_orderstatus = 'O'
GROUP BY 
    cr.r_name
HAVING 
    SUM(lp.l_extendedprice * (1 - lp.l_discount)) > 50000
ORDER BY 
    total_orders DESC;
