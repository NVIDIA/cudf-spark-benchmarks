WITH SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_availqty) AS total_avail_qty, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, st.total_avail_qty, st.avg_supply_cost
    FROM SupplierStats st
    JOIN supplier s ON s.s_suppkey = st.s_suppkey
    ORDER BY st.total_avail_qty DESC
    LIMIT 10
),
OrderStats AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS total_orders, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
CustomerRanked AS (
    SELECT cs.c_custkey, cs.c_name, cs.total_orders, cs.total_spent, RANK() OVER (ORDER BY cs.total_spent DESC) AS customer_rank
    FROM OrderStats cs
)
SELECT ts.s_name, cr.c_name, cr.total_orders, cr.total_spent, ts.avg_supply_cost
FROM TopSuppliers ts
JOIN CustomerRanked cr ON ts.total_avail_qty > cr.total_orders
ORDER BY ts.avg_supply_cost DESC, cr.total_spent DESC;
