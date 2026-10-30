WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT r.r_name, n.n_name, rs.s_suppkey, rs.s_name, rs.total_cost,
           ROW_NUMBER() OVER (PARTITION BY r.r_regionkey ORDER BY rs.total_cost DESC) AS rn
    FROM RankedSuppliers rs
    JOIN nation n ON rs.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1997-12-31'
    GROUP BY o.o_orderkey, o.o_orderdate
)
SELECT ts.r_name, ts.n_name, ts.s_name, ts.total_cost, os.revenue
FROM TopSuppliers ts
JOIN OrderSummary os ON ts.s_suppkey = (SELECT ps.ps_suppkey 
                                         FROM partsupp ps
                                         JOIN lineitem l ON ps.ps_partkey = l.l_partkey
                                         WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1997-12-31')
                                         GROUP BY ps.ps_suppkey
                                         ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC
                                         LIMIT 1)
WHERE ts.rn <= 5
ORDER BY ts.r_name, ts.total_cost DESC;