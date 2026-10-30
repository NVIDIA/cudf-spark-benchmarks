WITH top_suppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY total_supply_value DESC
    LIMIT 10
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
)
SELECT co.c_custkey, co.c_name, co.o_orderkey, co.o_orderdate, co.o_totalprice, ts.s_suppkey, ts.s_name, ts.total_supply_value
FROM customer_orders co
JOIN lineitem l ON co.o_orderkey = l.l_orderkey
JOIN top_suppliers ts ON l.l_suppkey = ts.s_suppkey
WHERE l.l_returnflag = 'N' AND l.l_linestatus = 'F'
ORDER BY co.o_totalprice DESC, ts.total_supply_value ASC
LIMIT 50;