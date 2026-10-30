WITH RECURSIVE CTE_Orders AS (
    SELECT
        o.o_orderkey,
        o.o_orderstatus,
        o.o_orderdate,
        o.o_totalprice,
        1 AS level
    FROM orders o
    WHERE o.o_orderstatus = 'O' AND o.o_orderdate < (cast('1998-10-01' as date) - INTERVAL '1 year')
    
    UNION ALL
    
    SELECT
        o.o_orderkey,
        o.o_orderstatus,
        o.o_orderdate,
        o.o_totalprice,
        cte.level + 1
    FROM orders o
    JOIN CTE_Orders cte ON o.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_name LIKE '%A%')
    WHERE o.o_orderdate < cte.o_orderdate AND o.o_orderstatus = 'O'
),
MainQuery AS (
    SELECT
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT c.c_custkey) AS unique_customers
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
      AND (p.p_size IS NULL OR p.p_size > 10)
      AND (o.o_totalprice NOT IN (SELECT DISTINCT l2.l_extendedprice FROM lineitem l2 WHERE l2.l_returnflag = 'R'))
    GROUP BY p.p_name
),
AggregatedResults AS (
    SELECT
        p_name,
        total_revenue,
        unique_customers,
        ROW_NUMBER() OVER (ORDER BY total_revenue DESC) AS revenue_rank,
        RANK() OVER (PARTITION BY unique_customers ORDER BY total_revenue DESC) AS customer_rank
    FROM MainQuery
)
SELECT
    ar.p_name,
    ar.total_revenue,
    ar.unique_customers,
    ar.revenue_rank,
    CASE 
        WHEN ar.total_revenue > (SELECT AVG(total_revenue) FROM MainQuery) THEN 'Above Average' 
        ELSE 'Below Average' 
    END AS performance_category
FROM AggregatedResults ar
LEFT JOIN region r ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n JOIN supplier s ON n.n_nationkey = s.s_nationkey WHERE s.s_acctbal IS NULL)
WHERE ar.revenue_rank < 10
ORDER BY ar.total_revenue DESC, ar.p_name
LIMIT 5 OFFSET 5;