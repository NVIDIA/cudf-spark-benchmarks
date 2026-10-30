WITH supplier_aggregate AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           s.s_nationkey, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost, 
           COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
top_suppliers AS (
    SELECT sa.s_suppkey, 
           sa.s_name, 
           na.n_name AS nation_name, 
           sa.total_supply_cost, 
           sa.part_count,
           DENSE_RANK() OVER (PARTITION BY na.n_regionkey ORDER BY sa.total_supply_cost DESC) AS rank_within_region
    FROM supplier_aggregate sa
    JOIN nation na ON sa.s_nationkey = na.n_nationkey
),
order_summary AS (
    SELECT o.o_orderkey, 
           o.o_custkey, 
           o.o_orderdate, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value, 
           MAX(l.l_shipdate) AS latest_ship_date
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey, o.o_orderdate
)
SELECT ts.s_name, 
       ts.nation_name, 
       ts.total_supply_cost, 
       os.total_order_value, 
       os.latest_ship_date
FROM top_suppliers ts
JOIN order_summary os ON ts.s_suppkey = os.o_custkey
WHERE ts.rank_within_region <= 10
ORDER BY ts.total_supply_cost DESC, os.total_order_value DESC
LIMIT 50;
