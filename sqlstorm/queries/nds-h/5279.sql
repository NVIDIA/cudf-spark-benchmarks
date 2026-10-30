WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, rs.TotalCost
    FROM RankedSuppliers rs
    JOIN supplier s ON rs.s_suppkey = s.s_suppkey
    ORDER BY rs.TotalCost DESC
    LIMIT 10
),
NationStats AS (
    SELECT n.n_nationkey, n.n_name, SUM(o.o_totalprice) AS TotalOrderValue
    FROM nation n
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT ts.s_name, ts.TotalCost, ns.n_name, ns.TotalOrderValue
FROM TopSuppliers ts
JOIN NationStats ns ON ts.s_nationkey = ns.n_nationkey
ORDER BY ts.TotalCost DESC, ns.TotalOrderValue DESC;
