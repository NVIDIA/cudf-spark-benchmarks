
WITH SupplierSummary AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_availqty) AS total_available_quantity, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, ss.total_available_quantity, ss.total_supply_cost,
           RANK() OVER (ORDER BY ss.total_supply_cost DESC) AS supply_rank
    FROM SupplierSummary ss
    JOIN supplier s ON ss.s_suppkey = s.s_suppkey
    WHERE ss.total_available_quantity > 100
),
OrderStats AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= DATE '1997-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate
)
SELECT ts.s_name, ts.total_available_quantity, ts.total_supply_cost, os.o_orderkey, os.o_orderdate, os.total_revenue
FROM TopSuppliers ts
JOIN OrderStats os ON os.o_orderdate = DATE '1998-10-01'
WHERE ts.supply_rank <= 5
ORDER BY ts.total_supply_cost DESC, os.total_revenue DESC;
