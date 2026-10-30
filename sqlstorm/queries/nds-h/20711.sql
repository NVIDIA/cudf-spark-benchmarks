WITH  price_cte AS (
    SELECT ps_partkey,
           SUM(ps_supplycost) AS total_supply_cost,
           COUNT(DISTINCT ps_suppkey) AS unique_suppliers
    FROM partsupp
    GROUP BY ps_partkey
),
filtered_parts AS (
    SELECT p.p_partkey,
           p.p_name,
           p.p_retailprice,
           COALESCE(price_cte.total_supply_cost, 0) AS total_supply_cost,
           CASE 
               WHEN p.p_retailprice IS NULL THEN 'Warranty Needed' 
               WHEN price_cte.total_supply_cost > p.p_retailprice THEN 'Underpriced'
               ELSE 'Value'
           END AS price_category
    FROM part p
    LEFT JOIN price_cte ON p.p_partkey = price_cte.ps_partkey
),
nation_supplier AS (
    SELECT n.n_nationkey,
           n.n_name,
           COUNT(s.s_suppkey) AS supplier_count
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
    HAVING COUNT(s.s_suppkey) > 0
),
ranking_orders AS (
    SELECT o.o_orderkey,
           o.o_orderdate,
           ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS rank_per_segment
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE c.c_mktsegment IS NOT NULL
),
final_summary AS (
    SELECT fp.p_partkey,
           fp.p_name,
           fp.total_supply_cost,
           fp.price_category,
           ns.n_name AS supplier_nation,
           ro.rank_per_segment
    FROM filtered_parts fp
    LEFT JOIN nation_supplier ns ON fp.p_partkey = ns.n_nationkey
    LEFT JOIN ranking_orders ro ON fp.p_partkey = ro.o_orderkey
)
SELECT f.p_partkey,
       f.p_name,
       f.total_supply_cost,
       f.price_category,
       f.supplier_nation,
       f.rank_per_segment,
       CASE 
           WHEN f.rank_per_segment IS NOT NULL THEN 'Ranked Order'
           ELSE 'Unranked Order'
       END AS order_rank_status
FROM final_summary f
WHERE f.total_supply_cost > (
    SELECT AVG(total_supply_cost) 
    FROM price_cte
)
OR f.price_category = 'Warranty Needed'
ORDER BY f.p_partkey, f.supplier_nation DESC NULLS LAST;
