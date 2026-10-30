
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2)
),
HighValueSupplier AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 100000
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        r.r_name AS region_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    si.s_name,
    si.region_name,
    COUNT(lo.o_orderkey) AS order_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(lo.o_totalprice) AS avg_order_value,
    ROW_NUMBER() OVER (PARTITION BY si.region_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
FROM 
    lineitem l
JOIN 
    RankedOrders lo ON l.l_orderkey = lo.o_orderkey
JOIN 
    HighValueSupplier hvs ON l.l_partkey = hvs.ps_partkey AND l.l_suppkey = hvs.ps_suppkey
JOIN 
    SupplierInfo si ON hvs.ps_suppkey = si.s_suppkey
GROUP BY 
    si.s_name, si.region_name
HAVING 
    COUNT(lo.o_orderkey) > 5
ORDER BY 
    revenue_rank;
