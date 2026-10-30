WITH  region_summary AS (
    SELECT r_regionkey,
           r_name,
           COUNT(n_nationkey) as nation_count
    FROM region
    LEFT JOIN nation ON r_regionkey = n_regionkey
    GROUP BY r_regionkey, r_name
),
customer_summary AS (
    SELECT c_nationkey,
           COUNT(DISTINCT o_orderkey) AS order_count,
           SUM(c_acctbal) AS total_acctbal,
           AVG(c_acctbal) AS average_acctbal
    FROM customer
    LEFT JOIN orders ON c_custkey = o_custkey
    GROUP BY c_nationkey
),
part_supp_summary AS (
    SELECT ps_partkey,
           SUM(ps_supplycost * ps_availqty) AS total_supplycost,
           MAX(ps_supplycost) AS max_supplycost
    FROM partsupp
    GROUP BY ps_partkey
),
ranked_orders AS (
    SELECT o_orderkey,
           o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o_orderstatus ORDER BY o_totalprice DESC) AS rank
    FROM orders
)
SELECT r.r_name,
       cs.order_count,
       ps.total_supplycost,
       COALESCE(cs.total_acctbal, 0) AS total_acctbal,
       RANK() OVER (ORDER BY COALESCE(cs.total_acctbal, 0) DESC) AS acctbal_rank,
       CASE 
           WHEN ps.total_supplycost IS NULL THEN 'Unknown'
           ELSE CASE 
               WHEN ps.total_supplycost < 1000 THEN 'Low'
               WHEN ps.total_supplycost BETWEEN 1000 AND 5000 THEN 'Medium'
               ELSE 'High'
           END
       END AS cost_category
FROM region_summary r
LEFT JOIN customer_summary cs ON r.r_regionkey = cs.c_nationkey
LEFT JOIN part_supp_summary ps ON r.r_regionkey = ps.ps_partkey
FULL OUTER JOIN ranked_orders ro ON cs.order_count > 5 OR (cs.order_count IS NULL AND ro.rank <= 10)
WHERE r.r_name LIKE 'A%' OR r.r_name IS NULL
ORDER BY total_acctbal DESC NULLS LAST, r.r_name;
