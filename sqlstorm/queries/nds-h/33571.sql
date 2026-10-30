WITH  SupplyChain AS (
    SELECT s.s_suppkey, s.s_name, p.p_partkey, p.p_name, ps.ps_availqty, 
           ps.ps_supplycost, ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ps.ps_supplycost DESC) as rnk
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE ps.ps_availqty > 0
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 
           CASE 
               WHEN c.c_acctbal >= 10000 THEN 'High Value'
               WHEN c.c_acctbal BETWEEN 5000 AND 9999 THEN 'Medium Value'
               ELSE 'Low Value' 
           END AS cust_value_segment
    FROM customer c
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1997-01-01' 
    GROUP BY o.o_orderkey, o.o_custkey
),
RankedOrders AS (
    SELECT o.cust_value_segment, os.total_order_value, 
           RANK() OVER (PARTITION BY o.cust_value_segment ORDER BY os.total_order_value DESC) as order_rank
    FROM OrderSummary os
    JOIN HighValueCustomers o ON os.o_custkey = o.c_custkey
)
SELECT r.cust_value_segment, COUNT(DISTINCT r.total_order_value) AS count_of_orders, 
       SUM(r.total_order_value) AS total_value_of_orders,
       MAX(s.p_name) AS most_expensive_product
FROM RankedOrders r
LEFT JOIN SupplyChain s ON r.cust_value_segment = 
    CASE 
        WHEN r.order_rank <= 5 THEN 'High Value'
        ELSE 'Other' 
    END
WHERE r.order_rank <= 10
GROUP BY r.cust_value_segment
HAVING SUM(r.total_order_value) > 10000
ORDER BY r.cust_value_segment;