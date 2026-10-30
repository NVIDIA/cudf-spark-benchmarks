WITH SupplierSummary AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
           COUNT(DISTINCT ps.ps_partkey) AS unique_parts
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total,
           COUNT(l.l_linenumber) AS line_item_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(od.order_total) AS total_spent,
           COUNT(od.o_orderkey) AS order_count
    FROM customer c
    JOIN OrderDetails od ON c.c_custkey = od.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
NationSupplier AS (
    SELECT n.n_name AS nation_name, SUM(ss.total_cost) AS total_supplier_cost,
           SUM(co.total_spent) AS total_customer_spending
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN SupplierSummary ss ON s.s_suppkey = ss.s_suppkey
    JOIN CustomerOrders co ON s.s_nationkey = co.c_custkey
    GROUP BY n.n_name
)
SELECT ns.nation_name, ns.total_supplier_cost, ns.total_customer_spending, 
       (ns.total_customer_spending / NULLIF(ns.total_supplier_cost, 0)) AS spending_over_cost_ratio
FROM NationSupplier ns
WHERE ns.total_supplier_cost > 0
ORDER BY spending_over_cost_ratio DESC
LIMIT 10;
