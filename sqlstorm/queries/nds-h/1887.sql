WITH  supplier_totals AS (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
customer_summary AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent,
           COUNT(o.o_orderkey) AS order_count, AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
lineitem_details AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_suppkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_lineitem_value
    FROM lineitem l
    WHERE l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1998-01-01'
    GROUP BY l.l_orderkey, l.l_partkey, l.l_suppkey
),
region_supplier AS (
    SELECT r.r_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_name
)
SELECT c.c_name, cs.total_spent, cs.order_count, cs.avg_order_value,
       COALESCE(rt.supplier_count, 0) AS region_supplier_count,
       COALESCE(st.total_supply_cost, 0) AS supplier_total_cost
FROM customer_summary cs
JOIN customer c ON cs.c_custkey = c.c_custkey
JOIN lineitem_details ld ON ld.l_suppkey = c.c_custkey
LEFT JOIN region_supplier rt ON rt.supplier_count > 0
LEFT JOIN supplier_totals st ON st.s_suppkey = ld.l_suppkey
WHERE cs.total_spent > 1000
ORDER BY cs.total_spent DESC
LIMIT 50;