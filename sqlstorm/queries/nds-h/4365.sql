WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2 WHERE o2.o_orderdate >= DATE '1997-01-01')
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
)
SELECT 
    p.p_name,
    p.p_brand,
    p.p_container,
    p.p_retailprice,
    COALESCE(SUM(lp.l_quantity), 0) AS total_quantity_sold,
    COALESCE(SUM(lp.l_extendedprice), 0) AS total_revenue,
    CASE 
        WHEN SUM(lp.l_extendedprice) IS NULL THEN 'No Revenue' 
        ELSE 'Revenue Recorded'
    END AS revenue_status,
    sr.total_avail_qty,
    sr.total_supply_cost
FROM 
    part p
LEFT JOIN 
    lineitem lp ON p.p_partkey = lp.l_partkey
LEFT JOIN 
    SupplierParts sr ON p.p_partkey = sr.ps_partkey
WHERE 
    p.p_retailprice > 50.00
    AND (SELECT COUNT(*) FROM RankedOrders ro WHERE ro.o_orderkey = lp.l_orderkey AND ro.order_rank = 1) > 0
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, p.p_container, p.p_retailprice, sr.total_avail_qty, sr.total_supply_cost
HAVING 
    COALESCE(SUM(lp.l_extendedprice), 0) > (SELECT AVG(l_extendedprice) FROM lineitem)
ORDER BY 
    total_revenue DESC
LIMIT 10;