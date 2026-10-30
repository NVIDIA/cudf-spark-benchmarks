WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT r.r_name, ns.n_name, rs.s_name, rs.total_supply_cost,
           RANK() OVER (PARTITION BY r.r_regionkey ORDER BY rs.total_supply_cost DESC) AS supplier_rank
    FROM RankedSuppliers rs
    JOIN nation ns ON rs.s_nationkey = ns.n_nationkey
    JOIN region r ON ns.n_regionkey = r.r_regionkey
)
SELECT t.r_name AS region, t.n_name AS nation, t.s_name AS supplier, t.total_supply_cost
FROM TopSuppliers t
WHERE t.supplier_rank <= 3
ORDER BY t.r_name, t.n_name, t.supplier_rank;
