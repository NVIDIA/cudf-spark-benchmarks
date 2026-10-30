
WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        COUNT(DISTINCT p.p_partkey) AS part_count,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_custkey) AS unique_customers
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
RankedOrders AS (
    SELECT 
        os.o_orderkey,
        os.total_revenue,
        os.o_orderstatus,
        RANK() OVER (PARTITION BY os.o_orderstatus ORDER BY os.total_revenue DESC) AS status_rank
    FROM 
        OrderSummary os
)
SELECT 
    r.r_name,
    COALESCE(SUM(ss.total_avail_qty), 0) AS total_available_quantity,
    COALESCE(SUM(ro.total_revenue), 0) AS total_revenue_for_region,
    CASE 
        WHEN COUNT(ro.o_orderkey) > 0 THEN AVG(ss.avg_supply_cost)
        ELSE NULL
    END AS avg_supply_cost
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierStats ss ON s.s_suppkey = ss.s_suppkey
LEFT JOIN 
    RankedOrders ro ON s.s_suppkey = ro.o_orderkey
GROUP BY 
    r.r_name
HAVING 
    COALESCE(SUM(ss.total_avail_qty), 0) > 1000 OR COALESCE(SUM(ro.total_revenue), 0) > 1000000
ORDER BY 
    r.r_name ASC;
