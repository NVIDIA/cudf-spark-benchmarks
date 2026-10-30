WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, rs.total_cost
    FROM RankedSuppliers rs
    JOIN supplier s ON rs.s_suppkey = s.s_suppkey
    ORDER BY rs.total_cost DESC
    LIMIT 10
),
OrderStats AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue, o.o_orderpriority
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY o.o_orderkey, o.o_orderpriority
),
FinalReport AS (
    SELECT ts.s_name, os.o_orderpriority, SUM(os.revenue) AS total_revenue
    FROM TopSuppliers ts
    JOIN partsupp ps ON ts.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN OrderStats os ON o.o_orderkey = os.o_orderkey
    GROUP BY ts.s_name, os.o_orderpriority
)
SELECT s.s_name, 
       o.o_orderpriority, 
       total_revenue,
       RANK() OVER (PARTITION BY o.o_orderpriority ORDER BY total_revenue DESC) AS rank_within_priority
FROM FinalReport s
JOIN OrderStats o ON s.o_orderpriority = o.o_orderpriority
ORDER BY o.o_orderpriority, total_revenue DESC;