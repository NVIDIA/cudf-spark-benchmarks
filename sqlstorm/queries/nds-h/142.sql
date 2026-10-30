WITH SupplierStats AS (
    SELECT s.s_suppkey,
           s.s_name,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
           COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT s.s_suppkey,
           s.s_name,
           ss.total_supply_value,
           ss.part_count,
           RANK() OVER (ORDER BY ss.total_supply_value DESC) AS rank
    FROM SupplierStats ss
    JOIN supplier s ON ss.s_suppkey = s.s_suppkey
),
OrderLineDetails AS (
    SELECT o.o_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
           COUNT(l.l_orderkey) AS line_count,
           o.o_orderdate,
           o.o_orderstatus
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus IN ('O', 'F') AND o.o_orderdate >= '1997-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
CustomerOrders AS (
    SELECT c.c_custkey,
           c.c_name,
           COUNT(o.o_orderkey) AS orders_count,
           SUM(ol.total_order_value) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN OrderLineDetails ol ON o.o_orderkey = ol.o_orderkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT t.r_name,
       COUNT(DISTINCT c.c_custkey) AS customer_count,
       SUM(co.total_spent) AS total_spending,
       AVG(co.total_spent) AS avg_spending_per_customer,
       MAX(co.orders_count) AS max_orders_by_customer,
       MIN(co.orders_count) AS min_orders_by_customer
FROM region t
LEFT JOIN nation n ON n.n_regionkey = t.r_regionkey
LEFT JOIN customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN CustomerOrders co ON c.c_custkey = co.c_custkey
GROUP BY t.r_name
ORDER BY t.r_name;