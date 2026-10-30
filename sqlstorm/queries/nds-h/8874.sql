WITH ranked_orders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_name, 
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate DESC) as order_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderstatus = 'O'
),
high_value_orders AS (
    SELECT ro.o_orderkey, ro.o_orderdate, ro.o_totalprice, ro.c_name
    FROM ranked_orders ro
    WHERE ro.order_rank <= 5
),
supplier_parts AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, p.p_name, s.s_name, 
           SUM(ps.ps_availqty) AS total_available_quantity, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey, ps.ps_suppkey, p.p_name, s.s_name
),
order_line_items AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_suppkey, l.l_quantity, l.l_extendedprice
    FROM lineitem l
    JOIN high_value_orders hvo ON l.l_orderkey = hvo.o_orderkey
)
SELECT hvo.o_orderkey, hvo.o_orderdate, hvo.c_name, 
       sp.p_name, sp.s_name, 
       oli.l_quantity, oli.l_extendedprice,
       sp.total_available_quantity, sp.total_supply_cost,
       (sp.total_supply_cost / NULLIF(sp.total_available_quantity, 0)) AS cost_per_unit
FROM high_value_orders hvo
JOIN order_line_items oli ON hvo.o_orderkey = oli.l_orderkey
JOIN supplier_parts sp ON oli.l_partkey = sp.ps_partkey AND oli.l_suppkey = sp.ps_suppkey
ORDER BY hvo.o_orderdate DESC, hvo.o_orderkey;
