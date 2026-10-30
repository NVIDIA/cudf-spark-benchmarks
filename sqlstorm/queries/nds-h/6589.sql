WITH top_suppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY total_supply_value DESC
    LIMIT 10
),
order_details AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey, o.o_orderdate
),
customer_summary AS (
    SELECT c.c_custkey, c.c_name, n.n_name AS nation_name, SUM(od.total_price) AS total_order_value
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN order_details od ON c.c_custkey = od.o_orderkey
    GROUP BY c.c_custkey, c.c_name, n.n_name
)
SELECT cs.c_name, cs.nation_name, cs.total_order_value, ts.s_name AS top_supplier_name, ts.total_supply_value
FROM customer_summary cs
JOIN top_suppliers ts ON cs.total_order_value > ts.total_supply_value
ORDER BY cs.total_order_value DESC, ts.total_supply_value DESC;
