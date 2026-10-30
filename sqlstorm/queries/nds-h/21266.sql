
WITH  customer_orders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O' OR o.o_orderstatus IS NULL
), ranked_orders AS (
    SELECT co.*, ROW_NUMBER() OVER (PARTITION BY co.c_custkey ORDER BY co.o_orderdate DESC) AS rnk
    FROM customer_orders co
), parts_supply AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, 
           SUM(ps.ps_supplycost * ps.ps_availqty) OVER (PARTITION BY ps.ps_partkey) AS total_supply_cost
    FROM partsupp ps
), regional_supplier AS (
    SELECT s.s_suppkey, s.s_name, r.r_name, SUM(l.l_extendedprice) AS total_sales
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN lineitem l ON s.s_suppkey = l.l_suppkey
    WHERE l.l_discount > 0.05
    GROUP BY s.s_suppkey, s.s_name, r.r_name
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 5000
)
SELECT DISTINCT 
    c.c_name,
    r.r_name AS ru_name,
    COALESCE(SUM(o.o_totalprice), 0) AS total_order_value,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    ps.total_supply_cost AS ps_total_supply_cost,
    CASE 
        WHEN COUNT(DISTINCT o.o_orderkey) > 10 THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END AS customer_type
FROM customer c
LEFT JOIN ranked_orders o ON c.c_custkey = o.c_custkey AND o.rnk = 1
LEFT JOIN regional_supplier r ON c.c_custkey = r.s_suppkey
LEFT JOIN parts_supply ps ON r.s_suppkey = ps.ps_suppkey
GROUP BY c.c_name, r.r_name, ps.total_supply_cost
HAVING SUM(o.o_totalprice) IS NOT NULL 
   AND COUNT(DISTINCT o.o_orderkey) IS NOT NULL
ORDER BY customer_type, total_order_value DESC
LIMIT 100 OFFSET 50;
