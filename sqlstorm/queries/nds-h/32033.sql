WITH  order_summaries AS (
    SELECT o.o_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
           RANK() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank_total
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
supplier_stats AS (
    SELECT s.s_suppkey,
           COUNT(DISTINCT ps.ps_partkey) AS supply_count,
           SUM(ps.ps_supplycost) AS total_cost,
           MAX(ps.ps_availqty) AS max_avail_qty,
           STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey
),
null_filtered_orders AS (
    SELECT o.o_orderkey,
           o.o_orderstatus,
           n.n_name AS nation_name,
           o.o_totalprice
    FROM orders o
    LEFT JOIN customer c ON o.o_custkey = c.c_custkey
    LEFT JOIN nation n ON c.c_nationkey = n.n_nationkey
    WHERE n.n_name IS NOT NULL AND o.o_totalprice > 1000
)
SELECT oss.o_orderkey,
       oss.total_price,
       ss.supply_count,
       ss.total_cost,
       COALESCE(ss.max_avail_qty, 0) AS max_avail_qty,
       nfo.o_orderstatus,
       nfo.nation_name
FROM order_summaries oss
FULL OUTER JOIN supplier_stats ss ON oss.rank_total = ss.supply_count
FULL OUTER JOIN null_filtered_orders nfo ON oss.o_orderkey = nfo.o_orderkey
WHERE (ss.total_cost IS NULL OR ss.total_cost > 5000)
   AND (nfo.o_orderstatus IS NOT NULL OR nfo.o_orderstatus <> 'F')
ORDER BY OSS.total_price DESC, ss.supply_count ASC;
