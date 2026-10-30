
WITH RegionalPerformance AS (
    SELECT 
        r.r_name AS region_name,
        SUM(CASE WHEN o.o_orderstatus = 'F' THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS total_freight_revenue,
        COUNT(DISTINCT o.o_orderkey) AS total_fulfilled_orders,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1997-12-31'
    GROUP BY 
        r.r_name
),
AggregateMetrics AS (
    SELECT 
        AVG(total_freight_revenue) AS avg_revenue_per_region,
        SUM(total_fulfilled_orders) AS total_orders,
        COUNT(DISTINCT region_name) AS distinct_regions
    FROM 
        RegionalPerformance
)
SELECT 
    rp.region_name,
    rp.total_freight_revenue,
    rp.total_fulfilled_orders,
    rp.avg_order_value,
    am.avg_revenue_per_region,
    am.total_orders,
    am.distinct_regions
FROM 
    RegionalPerformance rp,
    AggregateMetrics am
ORDER BY 
    rp.total_freight_revenue DESC;
