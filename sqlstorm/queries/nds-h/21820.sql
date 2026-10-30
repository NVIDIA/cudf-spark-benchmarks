WITH  top_customers AS (
    SELECT c_custkey, c_name, SUM(o_totalprice) AS total_spent
    FROM customer
    JOIN orders ON c_custkey = o_custkey
    GROUP BY c_custkey, c_name
    HAVING SUM(o_totalprice) > 100000
),
high_value_parts AS (
    SELECT p_partkey, p_name, p_retailprice
    FROM part
    WHERE p_retailprice > (SELECT AVG(p_retailprice) FROM part) 
),
supplier_info AS (
    SELECT s_nationkey, AVG(s_acctbal) AS avg_acctbal
    FROM supplier
    GROUP BY s_nationkey
),
ranked_lineitems AS (
    SELECT l_orderkey, l_partkey, l_suppkey, 
           ROW_NUMBER() OVER (PARTITION BY l_orderkey ORDER BY l_extendedprice DESC) AS item_rank,
           l_quantity, l_extendedprice
    FROM lineitem
    WHERE l_returnflag = 'N'
),
order_summary AS (
    SELECT o_orderkey, SUM(l_extendedprice * (1 - l_discount)) AS order_value
    FROM lineitem
    JOIN orders ON orders.o_orderkey = lineitem.l_orderkey
    WHERE orders.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
    GROUP BY o_orderkey
)
SELECT 
    nt.n_name AS nation_name,
    tc.c_name AS top_customer,
    hp.p_name AS high_value_part,
    COUNT(DISTINCT os.o_orderkey) AS total_orders,
    SUM(os.order_value) AS total_revenue,
    MAX(s.avg_acctbal) AS highest_supplier_acctbal
FROM top_customers tc
JOIN nation nt ON tc.c_custkey = nt.n_nationkey
JOIN high_value_parts hp ON hp.p_partkey IN (
    SELECT ps_partkey
    FROM partsupp
    WHERE ps_supplycost < (SELECT AVG(ps_supplycost) FROM partsupp)
)
JOIN ranked_lineitems rl ON tc.c_custkey = rl.l_suppkey
LEFT JOIN supplier_info s ON nt.n_nationkey = s.s_nationkey
JOIN order_summary os ON os.o_orderkey = rl.l_orderkey
WHERE rl.item_rank <= 3
GROUP BY nt.n_name, tc.c_name, hp.p_name
HAVING SUM(os.order_value) > 50000 
   OR COUNT(DISTINCT os.o_orderkey) > 10
ORDER BY total_revenue DESC, nation_name ASC, total_orders DESC;