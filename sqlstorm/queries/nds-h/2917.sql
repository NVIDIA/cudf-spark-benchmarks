WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
),
SupplierCost AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
CustomerRegion AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        n.n_name AS nation_name,
        r.r_name AS region_name
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
LineitemSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        AVG(l.l_quantity) AS avg_quantity,
        SUM(l.l_tax) AS total_tax
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    cr.region_name,
    cr.nation_name,
    SUM(ls.total_revenue) AS total_revenue,
    COUNT(DISTINCT lo.o_orderkey) AS total_orders,
    MIN(lo.o_totalprice) AS min_order_price,
    MAX(lo.o_totalprice) AS max_order_price,
    SUM(sc.total_supply_cost) AS total_supply_cost
FROM 
    CustomerRegion cr
LEFT JOIN 
    RankedOrders lo ON cr.c_custkey = lo.o_orderkey
JOIN 
    LineitemSummary ls ON ls.l_orderkey = lo.o_orderkey
JOIN 
    SupplierCost sc ON sc.ps_partkey = lo.o_orderkey
GROUP BY 
    cr.region_name, cr.nation_name
HAVING 
    SUM(ls.total_revenue) > 1000000
ORDER BY 
    total_revenue DESC, cr.region_name ASC;