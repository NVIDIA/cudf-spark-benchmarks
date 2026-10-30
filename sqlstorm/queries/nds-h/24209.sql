
WITH  cust_orders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > (SELECT AVG(c1.c_acctbal) FROM customer c1)
),
high_value_parts AS (
    SELECT p.p_partkey, p.p_name, MAX(ps.ps_supplycost) AS max_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
    HAVING MAX(ps.ps_supplycost) > 100.00
),
supply_stats AS (
    SELECT s.s_suppkey, SUM(ps.ps_availqty) AS total_availqty, COUNT(DISTINCT ps.ps_partkey) AS total_parts
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
    HAVING SUM(ps.ps_availqty) > 500 OR COUNT(DISTINCT ps.ps_partkey) > 5
),
unique_nations AS (
    SELECT DISTINCT n.n_name
    FROM nation n
    WHERE n.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name LIKE 'Eu%')
),
order_summary AS (
    SELECT oo.o_orderkey, oo.o_totalprice,
           CASE 
               WHEN oo.o_totalprice > 1000 THEN 'High Value'
               WHEN oo.o_totalprice BETWEEN 500 AND 1000 THEN 'Medium Value'
               ELSE 'Low Value'
           END AS price_category
    FROM orders oo
)
SELECT co.c_custkey, co.c_name, os.o_orderkey, os.o_totalprice, os.price_category,
       CASE 
           WHEN os.price_category = 'High Value' THEN 'VIP'
           ELSE NULL
       END AS customer_status,
       np.n_name AS nation_name
FROM cust_orders co
LEFT JOIN order_summary os ON co.o_orderkey = os.o_orderkey
LEFT JOIN unique_nations np ON np.n_name IS NOT NULL
WHERE (co.order_rank = 1 OR co.order_rank IS NULL)
      AND EXISTS (SELECT 1 FROM high_value_parts hp WHERE hp.max_supplycost < 150.00)
      AND os.o_totalprice < (SELECT AVG(o2.o_totalprice) FROM orders o2 WHERE o2.o_orderstatus = 'O')
ORDER BY co.c_custkey, os.o_totalprice DESC;
