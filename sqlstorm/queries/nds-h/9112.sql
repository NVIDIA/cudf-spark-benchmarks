WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
), TopSuppliers AS (
    SELECT r.r_name, r.r_regionkey, n.n_name, rs.s_suppkey, rs.s_name, rs.total_cost,
           ROW_NUMBER() OVER (PARTITION BY r.r_regionkey ORDER BY rs.total_cost DESC) AS rank
    FROM RankedSuppliers rs
    JOIN nation n ON rs.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT ts.r_name, ts.n_name, ts.s_name, ts.total_cost
FROM TopSuppliers ts
WHERE ts.rank <= 5
ORDER BY ts.r_regionkey, ts.total_cost DESC;
