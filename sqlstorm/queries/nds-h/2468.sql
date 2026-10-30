
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighRevenueOrders AS (
    SELECT 
        ro.o_orderkey, 
        ro.total_revenue
    FROM 
        RankedOrders ro
    WHERE 
        ro.order_rank = 1 AND ro.total_revenue > (
            SELECT AVG(total_revenue) FROM RankedOrders
        )
)
SELECT 
    ss.s_suppkey,
    ss.s_name,
    SUM(hro.total_revenue) AS impactful_revenue,
    CASE 
        WHEN COUNT(hro.o_orderkey) > 5 THEN 'High Frequency'
        ELSE 'Low Frequency'
    END AS order_frequency,
    ss.total_supply_cost,
    ss.unique_parts
FROM 
    HighRevenueOrders hro
FULL OUTER JOIN 
    SupplierStats ss ON ss.s_suppkey = hro.o_orderkey
GROUP BY 
    ss.s_suppkey, ss.s_name, ss.total_supply_cost, ss.unique_parts
HAVING 
    SUM(hro.total_revenue) > (SELECT AVG(total_revenue) FROM HighRevenueOrders)
ORDER BY 
    impactful_revenue DESC, ss.unique_parts DESC;
