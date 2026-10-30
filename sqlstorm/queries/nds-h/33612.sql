
WITH  ranked_orders AS (
    SELECT o_orderkey, 
           o_custkey, 
           o_orderstatus, 
           o_orderdate, 
           o_totalprice, 
           ROW_NUMBER() OVER (PARTITION BY o_orderstatus ORDER BY o_totalprice DESC) AS rank
    FROM orders
),
supplier_part_availability AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           p.p_partkey, 
           p.p_name,
           SUM(ps.ps_availqty) AS total_available
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE s.s_acctbal IS NOT NULL 
    GROUP BY s.s_suppkey, s.s_name, p.p_partkey, p.p_name
    HAVING SUM(ps.ps_availqty) > 0
),
order_line_items AS (
    SELECT l.l_orderkey,
           l.l_partkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM lineitem l
    WHERE l.l_shipdate >= '1996-01-01' AND l.l_shipdate < '1997-01-01'
    GROUP BY l.l_orderkey, l.l_partkey
)
SELECT 
    r.o_orderkey,
    r.o_orderdate, 
    COALESCE(SUM(oli.revenue), 0) AS total_revenue,
    s.s_name AS supplier_name,
    p.p_name AS part_name
FROM ranked_orders r
LEFT JOIN order_line_items oli ON r.o_orderkey = oli.l_orderkey
LEFT JOIN supplier_part_availability s ON s.p_partkey = oli.l_partkey
JOIN part p ON p.p_partkey = oli.l_partkey
WHERE r.rank <= 10
GROUP BY r.o_orderkey, r.o_orderdate, s.s_name, p.p_name
ORDER BY r.o_orderdate DESC, total_revenue DESC;
