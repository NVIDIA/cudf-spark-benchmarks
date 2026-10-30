
WITH SupplierCosts AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn,
        o.o_custkey
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '6 months'
),
LineItemSummaries AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(*) AS total_items
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(COALESCE(SC.total_supply_cost, 0)) AS total_supply_costs,
    SUM(COALESCE(LI.total_revenue, 0)) AS total_lineitem_revenue,
    AVG(CASE WHEN r.r_regionkey IS NOT NULL THEN o.o_totalprice ELSE NULL END) AS avg_order_price_in_region,
    COUNT(DISTINCT CASE WHEN r.r_name IS NOT NULL THEN r.r_name END) AS distinct_regions
FROM 
    customer c
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    RecentOrders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    SupplierCosts SC ON SC.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_brand = 'Brand#1'))
LEFT JOIN 
    LineItemSummaries LI ON LI.l_orderkey = o.o_orderkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey 
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    customer_count DESC;
