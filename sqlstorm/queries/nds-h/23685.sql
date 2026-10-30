
WITH RecursiveCTE AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rn
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        ps.ps_supplycost < (SELECT AVG(ps_supplycost) FROM partsupp)
), 
AggregatedData AS (
    SELECT 
        r.r_name AS region_name,
        SUM(CASE WHEN c.c_mktsegment = 'SMALL' THEN l.l_extendedprice - l.l_discount * l.l_extendedprice ELSE 0 END) AS small_market_total,
        SUM(CASE WHEN c.c_mktsegment = 'LARGE' THEN l.l_extendedprice - l.l_discount * l.l_extendedprice ELSE 0 END) AS large_market_total,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        region r
    LEFT JOIN 
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
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    GROUP BY 
        r.r_name
), 
FilteredOrders AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY region_name ORDER BY total_orders DESC) AS order_rank
    FROM 
        AggregatedData
    WHERE 
        small_market_total IS NOT NULL 
        AND large_market_total IS NOT NULL
        AND (small_market_total + large_market_total > 0)
)

SELECT 
    f.region_name,
    f.small_market_total,
    f.large_market_total,
    COALESCE((
        SELECT MAX(ps_supplycost) 
        FROM RecursiveCTE 
        WHERE p_partkey IN (SELECT p_partkey FROM part WHERE p_size BETWEEN 10 AND 20)
    ), 0) AS max_cost_for_part_size,
    (f.small_market_total + f.large_market_total) / NULLIF(f.total_orders, 0) AS avg_price_per_order
FROM 
    FilteredOrders f
WHERE 
    f.order_rank <= 5
ORDER BY 
    f.total_orders DESC,
    f.region_name ASC;
