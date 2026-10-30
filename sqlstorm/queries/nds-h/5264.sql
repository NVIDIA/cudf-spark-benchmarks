WITH ranked_supplier AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
), high_value_suppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, r.total_supply_cost
    FROM ranked_supplier r
    JOIN supplier s ON r.s_suppkey = s.s_suppkey
    WHERE r.total_supply_cost > 1000000
), customer_orders AS (
    SELECT o.o_orderkey, c.c_custkey, c.c_name, o.o_orderdate, o.o_totalprice, o.o_orderstatus
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= '1996-01-01'
), order_line_items AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_value
    FROM lineitem l
    GROUP BY l.l_orderkey
), complete_report AS (
    SELECT co.o_orderkey, co.c_custkey, co.c_name, co.o_orderdate, co.o_totalprice, co.o_orderstatus,
           oli.total_line_value, hvs.s_suppkey, hvs.s_name, hvs.s_acctbal
    FROM customer_orders co
    JOIN order_line_items oli ON co.o_orderkey = oli.l_orderkey
    JOIN high_value_suppliers hvs ON oli.total_line_value > hvs.total_supply_cost
)
SELECT cr.c_custkey, cr.c_name, cr.o_orderkey, cr.o_orderdate, cr.o_totalprice, cr.o_orderstatus,
       hvs.s_name, hvs.s_acctbal, SUM(oli.total_line_value) AS total_discounted_value
FROM complete_report cr
JOIN order_line_items oli ON cr.o_orderkey = oli.l_orderkey
JOIN high_value_suppliers hvs ON oli.total_line_value > hvs.total_supply_cost
GROUP BY cr.c_custkey, cr.c_name, cr.o_orderkey, cr.o_orderdate, cr.o_totalprice, cr.o_orderstatus, hvs.s_name, hvs.s_acctbal
ORDER BY total_discounted_value DESC;