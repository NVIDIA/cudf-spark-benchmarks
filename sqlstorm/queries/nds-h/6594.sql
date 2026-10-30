WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
           RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT r.r_regionkey, r.r_name, ns.n_name AS nation_name, rs.s_suppkey, rs.s_name, rs.total_cost
    FROM RankedSuppliers rs
    JOIN nation ns ON rs.s_nationkey = ns.n_nationkey
    JOIN region r ON ns.n_regionkey = r.r_regionkey
    WHERE rs.rank <= 3
)
SELECT ts.r_regionkey, ts.r_name, COUNT(ts.s_suppkey) AS top_supplier_count, 
       AVG(ts.total_cost) AS avg_total_cost
FROM TopSuppliers ts
GROUP BY ts.r_regionkey, ts.r_name
ORDER BY ts.r_regionkey;
