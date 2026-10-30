
WITH supplier_stats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost) DESC) AS rank_within_nation
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
product_sales AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderdate >= '1997-01-01' 
    GROUP BY l.l_partkey
),
customer_info AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        DENSE_RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS spending_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL
    GROUP BY c.c_custkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(ps.total_sales, 0) AS total_sales,
    CASE 
        WHEN cs.total_spent IS NULL THEN 'No Spending'
        WHEN cs.spending_rank <= 10 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_status,
    ss.part_count,
    ss.total_available,
    ss.avg_supply_cost,
    ss.rank_within_nation
FROM part p
LEFT JOIN product_sales ps ON p.p_partkey = ps.l_partkey
LEFT JOIN customer_info cs ON cs.total_spent = (SELECT MAX(total_spent) FROM customer_info)
LEFT JOIN supplier_stats ss ON p.p_partkey = ss.s_suppkey OR ss.s_suppkey IS NULL
WHERE (ps.total_sales > 1000 OR ps.total_sales IS NULL)
  AND (ss.rank_within_nation IS NULL OR ss.rank_within_nation < 5)
ORDER BY customer_status DESC, total_sales DESC
LIMIT 50;
