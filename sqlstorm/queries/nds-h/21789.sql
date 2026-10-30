
WITH ranked_orders AS (
    SELECT o.o_orderkey, o.o_totalprice, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '1996-01-01' AND o.o_orderstatus IN ('O', 'F')
),
part_supplier AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
high_value_parts AS (
    SELECT p.p_partkey, p.p_name, p.p_mfgr, p.p_retailprice
    FROM part p
    WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
),
customer_order_summary AS (
    SELECT c.c_custkey, c.c_name,
           SUM(o.o_totalprice) AS total_orders,
           COUNT(o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
top_customers AS (
    SELECT cus.c_custkey, cus.c_name,
           RANK() OVER (ORDER BY cus.total_orders DESC) AS customer_rank
    FROM customer_order_summary cus
    WHERE cus.order_count > 5
)

SELECT DISTINCT 
    r.r_name,
    ns.n_name AS nation_name,
    p.p_name,
    l.l_shipmode,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(COALESCE(l.l_extendedprice * (1 - l.l_discount), 0)) AS net_revenue
FROM region r
JOIN nation ns ON r.r_regionkey = ns.n_regionkey
LEFT JOIN supplier s ON ns.n_nationkey = s.s_nationkey
LEFT JOIN part_supplier ps ON s.s_suppkey = ps.ps_suppkey
JOIN high_value_parts p ON ps.ps_partkey = p.p_partkey
JOIN lineitem l ON l.l_partkey = p.p_partkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
WHERE (o.o_orderstatus = 'O' OR o.o_orderstatus = 'F') 
  AND l.l_shipdate IS NOT NULL 
  AND (l.l_returnflag IS NULL OR l.l_returnflag <> 'R')
  AND l.l_quantity BETWEEN 10 AND 100
  AND EXISTS (SELECT 1 FROM top_customers tc WHERE tc.c_custkey = o.o_custkey)
GROUP BY r.r_name, ns.n_name, p.p_name, l.l_shipmode
HAVING SUM(l.l_tax) IS NOT NULL
ORDER BY r.r_name, net_revenue DESC;
