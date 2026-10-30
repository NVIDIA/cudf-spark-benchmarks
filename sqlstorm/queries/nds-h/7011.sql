
WITH ranked_orders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_name, c.c_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
),
top_orders AS (
    SELECT r.o_orderkey, r.o_orderdate, r.o_totalprice, r.c_name, r.c_acctbal
    FROM ranked_orders r
    WHERE r.rank <= 5
),
supplier_parts AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
detailed_orders AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_suppkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           MIN(l.l_shipdate) AS earliest_shipdate
    FROM lineitem l
    JOIN top_orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY l.l_orderkey, l.l_partkey, l.l_suppkey
)
SELECT o.o_orderkey, o.o_orderdate, o.c_name, d.total_revenue, sp.total_supply_cost,
       CASE 
           WHEN sp.total_supply_cost < 5000 THEN 'Low Cost'
           WHEN sp.total_supply_cost BETWEEN 5000 AND 15000 THEN 'Medium Cost'
           ELSE 'High Cost'
       END AS supply_cost_category
FROM detailed_orders d
JOIN supplier_parts sp ON d.l_partkey = sp.ps_partkey
JOIN top_orders o ON d.l_orderkey = o.o_orderkey
ORDER BY d.total_revenue DESC, o.o_orderdate ASC;
