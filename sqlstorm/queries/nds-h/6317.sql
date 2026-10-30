WITH ranked_orders AS (
    SELECT o.o_orderkey, 
           o.o_orderdate, 
           o.o_totalprice, 
           c.c_mktsegment, 
           ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
),
supplier_stats AS (
    SELECT ps.ps_suppkey, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost, 
           COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_size > 20
    GROUP BY ps.ps_suppkey
),
lineitem_summary AS (
    SELECT l.l_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM lineitem l
    WHERE l.l_shipdate >= DATE '1995-07-01'
    GROUP BY l.l_orderkey
)
SELECT r.o_orderkey, 
       r.o_orderdate, 
       r.o_totalprice, 
       r.c_mktsegment, 
       COALESCE(ls.revenue, 0) AS revenue, 
       ss.total_cost, 
       ss.part_count
FROM ranked_orders r
LEFT JOIN lineitem_summary ls ON r.o_orderkey = ls.l_orderkey
JOIN supplier_stats ss ON ss.ps_suppkey = (
    SELECT ps.ps_suppkey 
    FROM partsupp ps 
    JOIN part p ON ps.ps_partkey = p.p_partkey 
    ORDER BY ps.ps_supplycost * ps.ps_availqty DESC 
    LIMIT 1
)
WHERE r.rank <= 10;