WITH ranked_suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS supplier_rank,
        s.s_acctbal,
        n.n_nationkey
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
market_segment_totals AS (
    SELECT 
        c.c_mktsegment,
        SUM(o.o_totalprice) AS total_revenue,
        AVG(CASE WHEN o.o_orderstatus = 'O' THEN o.o_totalprice ELSE NULL END) AS avg_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_mktsegment
),
part_supplier_prices AS (
    SELECT 
        ps.ps_partkey,
        MIN(ps.ps_supplycost) AS min_supplycost,
        MAX(ps.ps_supplycost) AS max_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
    HAVING COUNT(*) > 1
)
SELECT 
    r.r_name,
    p.p_name,
    ss.s_name AS supplier_name,
    COALESCE(ps.min_supplycost, 0) AS min_cost,
    COALESCE(ps.max_supplycost, 0) AS max_cost,
    ms.total_revenue,
    ms.avg_order_value,
    ss.s_acctbal,
    ROW_NUMBER() OVER (PARTITION BY r.r_regionkey ORDER BY ss.s_acctbal DESC) AS region_rank
FROM part p
JOIN part_supplier_prices ps ON p.p_partkey = ps.ps_partkey
FULL OUTER JOIN ranked_suppliers ss ON ps.ps_partkey = ss.s_suppkey 
JOIN region r ON ss.n_nationkey = r.r_regionkey
LEFT JOIN market_segment_totals ms ON ms.c_mktsegment = 'AUTO'
WHERE 
    (p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice > 100.00) OR p.p_brand IS NULL)
    AND (ss.s_acctbal BETWEEN 500.00 AND 1500.00 OR ss.s_acctbal IS NULL)
    AND NOT EXISTS (
        SELECT 1 
        FROM lineitem l 
        WHERE l.l_partkey = p.p_partkey 
        AND l.l_returnflag = 'R'
    )
ORDER BY 
    r.r_name,
    supplier_rank;
