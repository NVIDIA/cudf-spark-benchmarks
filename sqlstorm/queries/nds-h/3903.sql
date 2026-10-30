WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_quantity,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
DiscountedSales AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_after_discount
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '1997-01-01'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    p.p_name,
    COUNT(DISTINCT d.l_orderkey) AS total_orders,
    SUM(s.total_supplycost) AS total_supply_cost,
    AVG(o.o_totalprice) AS avg_order_price,
    CASE 
        WHEN AVG(o.o_totalprice) IS NULL THEN 'No Orders'
        ELSE 'Orders Exist'
    END AS order_status,
    r.r_name AS region_name
FROM 
    part p
LEFT JOIN 
    SupplierParts s ON p.p_partkey = s.ps_partkey
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    RankedOrders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    supplier sp ON s.ps_suppkey = sp.s_suppkey
LEFT JOIN 
    nation n ON sp.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    DiscountedSales d ON l.l_orderkey = d.l_orderkey
WHERE 
    p.p_size > 10 AND (s.total_quantity IS NULL OR s.total_quantity >= 100)
GROUP BY 
    p.p_name, r.r_name
HAVING 
    COUNT(DISTINCT d.l_orderkey) > 0 OR COUNT(DISTINCT o.o_orderkey) > 0
ORDER BY 
    region_name, total_orders DESC;