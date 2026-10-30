WITH  max_supplycost AS (
    SELECT ps_partkey, MAX(ps_supplycost) AS max_cost
    FROM partsupp
    GROUP BY ps_partkey
), ranked_orders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice,
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '1997-01-01'
), customer_orders AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, coalesce(SUM(o.o_totalprice), 0) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_acctbal
), detailed_lineitems AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_suppkey, l.l_quantity,
           l.l_extendedprice, l.l_discount, l.l_tax,
           ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_linenumber) AS line_item_number
    FROM lineitem l
    WHERE l.l_shipdate > cast('1998-10-01' as date) - INTERVAL '30 day'
)
SELECT co.c_name, 
       COALESCE(SUM(dli.l_extendedprice), 0) AS total_extended_price,
       COALESCE(SUM(dli.l_discount), 0) AS total_discount,
       COALESCE(mc.max_cost, 0) AS max_part_supply_cost,
       CASE WHEN co.total_spent > 1000 THEN 'VIP' ELSE 'Regular' END AS customer_status,
       RANK() OVER (ORDER BY SUM(dli.l_extendedprice) DESC) AS customer_rank
FROM customer_orders co
LEFT JOIN detailed_lineitems dli ON co.c_custkey = dli.l_orderkey
LEFT JOIN max_supplycost mc ON dli.l_partkey = mc.ps_partkey
GROUP BY co.c_name, co.total_spent, mc.max_cost
HAVING SUM(dli.l_extendedprice) > 0 AND MAX(dli.line_item_number) < 5
ORDER BY customer_rank
LIMIT 10;