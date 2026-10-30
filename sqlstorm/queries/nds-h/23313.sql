WITH ranked_parts AS (
    SELECT p.p_partkey,
           p.p_name,
           p.p_retailprice,
           p.p_mfgr,
           p.p_brand,
           ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rn
    FROM part p
    WHERE p.p_size IS NOT NULL AND p.p_retailprice > 0
),
supplier_details AS (
    SELECT s.s_suppkey,
           s.s_name,
           s.s_acctbal,
           s.s_nationkey,
           n.n_name AS nation_name,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn_sup
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal IS NOT NULL
),
available_parts AS (
    SELECT ps.ps_partkey,
           SUM(ps.ps_availqty) AS total_avail_qty,
           MIN(ps.ps_supplycost) AS min_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
filtered_orders AS (
    SELECT o.o_orderkey,
           COUNT(DISTINCT li.l_orderkey) FILTER (WHERE li.l_returnflag = 'R') AS returned_items,
           SUM(o.o_totalprice) AS total_order_value
    FROM orders o
    LEFT JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE o.o_orderdate > '1997-01-01' AND o.o_orderstatus IN ('O', 'F')
    GROUP BY o.o_orderkey
)
SELECT r.p_partkey,
       r.p_name,
       r.p_retailprice,
       sd.s_name AS supplier_name,
       ad.total_avail_qty,
       fo.total_order_value,
       COALESCE(sd.rn_sup, 0) AS supplier_rank,
       CASE 
           WHEN fo.total_order_value > 10000 THEN 'High Value'
           WHEN fo.total_order_value BETWEEN 5000 AND 10000 THEN 'Medium Value'
           ELSE 'Low Value'
       END AS order_value_category
FROM ranked_parts r
LEFT JOIN available_parts ad ON r.p_partkey = ad.ps_partkey
LEFT JOIN supplier_details sd ON ad.ps_partkey = sd.s_suppkey
LEFT JOIN filtered_orders fo ON r.p_partkey = fo.o_orderkey
WHERE (ad.total_avail_qty IS NULL OR ad.total_avail_qty < 10)
   OR (sd.s_acctbal - coalesce(fo.total_order_value, 0) > 5000)
ORDER BY r.p_retailprice ASC, sd.s_name DESC
LIMIT 100 OFFSET 10;