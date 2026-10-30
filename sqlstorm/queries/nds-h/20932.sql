
WITH  nation_summary AS (
    SELECT n.n_nationkey, n.n_name, SUM(s.s_acctbal) AS total_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(s.s_acctbal) DESC) AS rn
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name, n.n_regionkey
),
part_summary AS (
    SELECT p.p_partkey, p.p_brand,
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_brand
),
order_stats AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderstatus,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
           COUNT(*) AS line_item_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= DATE '1995-01-01'
    GROUP BY o.o_orderkey, o.o_custkey, o.o_orderstatus
),
ranked_orders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderstatus, o.revenue,
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.revenue DESC) AS revenue_rank
    FROM order_stats o
)
SELECT ns.n_name, ps.p_brand, 
       COALESCE(SUM(rs.revenue), 0) AS total_revenue,
       COUNT(DISTINCT ps.p_partkey) FILTER (WHERE ps.supplier_count > 1) AS diverse_parts,
       (CASE WHEN COUNT(DISTINCT ps.p_partkey) = 0 
            THEN 'No Parts'
            ELSE 'Parts available' END) AS part_availability,
       STRING_AGG(DISTINCT ns.n_name || ': ' || ns.total_acctbal) AS nation_summary
FROM nation_summary ns
FULL OUTER JOIN part_summary ps ON ns.n_nationkey = ps.p_partkey % 10  
LEFT JOIN ranked_orders rs ON ns.n_nationkey = rs.o_custkey
WHERE ns.rn <= 3 AND ps.avg_supply_cost < 50.00
GROUP BY ns.n_name, ps.p_brand
ORDER BY total_revenue DESC, part_availability DESC
LIMIT 10;
