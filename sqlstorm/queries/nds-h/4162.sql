
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey, o.o_orderdate
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
RecentOrders AS (
    SELECT 
        r.o_custkey AS custkey,
        r.o_orderkey,
        r.total_revenue
    FROM 
        RankedOrders r
    WHERE 
        r.order_rank = 1
)
SELECT 
    COALESCE(r.custkey, s.s_suppkey) AS identifier,
    r.o_orderkey,
    r.total_revenue,
    s.total_parts,
    s.avg_supply_cost
FROM 
    RecentOrders r
FULL OUTER JOIN 
    SupplierStats s ON r.custkey = s.s_suppkey
WHERE 
    (r.total_revenue > 10000 OR s.avg_supply_cost IS NULL)
ORDER BY 
    total_revenue DESC NULLS LAST, 
    identifier;
