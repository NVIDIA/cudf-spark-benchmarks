WITH  cust_orders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate ASC) AS order_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
),
avg_order_value AS (
    SELECT c_custkey, AVG(o_totalprice) AS avg_value
    FROM cust_orders
    GROUP BY c_custkey
),
recent_high_orders AS (
    SELECT c.c_custkey, c.c_name, co.o_orderkey, co.o_orderdate, co.o_totalprice
    FROM customer c
    JOIN cust_orders co ON c.c_custkey = co.c_custkey
    WHERE co.order_rank <= 5
      AND co.o_totalprice > (SELECT AVG(avg_value) FROM avg_order_value WHERE c_custkey = avg_order_value.c_custkey)
),
supplier_summary AS (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
lineitem_summary AS (
    SELECT l.l_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    GROUP BY l.l_partkey
),
parts_info AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_type,
           COALESCE(ps.total_supplycost, 0) AS total_supplycost,
           COALESCE(ls.total_revenue, 0) AS total_revenue,
           (COALESCE(ls.total_revenue, 0) - COALESCE(ps.total_supplycost, 0)) AS profit
    FROM part p
    LEFT JOIN supplier_summary ps ON p.p_partkey = ps.s_suppkey
    LEFT JOIN lineitem_summary ls ON p.p_partkey = ls.l_partkey
)
SELECT r.r_name, n.n_name, COUNT(DISTINCT co.o_orderkey) AS total_orders,
       SUM(pi.profit) AS total_profit,
       RANK() OVER (ORDER BY SUM(pi.profit) DESC) AS profit_rank
FROM recent_high_orders co
JOIN nation n ON co.c_custkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
JOIN parts_info pi ON co.o_orderkey = pi.p_partkey
GROUP BY r.r_name, n.n_name
HAVING SUM(pi.profit) IS NOT NULL
ORDER BY total_profit DESC
LIMIT 10;
