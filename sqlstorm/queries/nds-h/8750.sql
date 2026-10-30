
WITH  SupplierRank AS (
    SELECT s.s_suppkey, s.s_name, p.p_partkey, SUM(ps.ps_supplycost * l.l_quantity) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON p.p_partkey = ps.ps_partkey
    JOIN lineitem l ON l.l_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name, p.p_partkey
),
RankedSuppliers AS (
    SELECT sr.p_partkey, s.s_suppkey, s.s_name, SUM(sr.total_cost) AS aggregate_cost,
           RANK() OVER (PARTITION BY sr.p_partkey ORDER BY SUM(sr.total_cost) DESC) AS supplier_rank
    FROM SupplierRank sr
    JOIN supplier s ON s.s_suppkey = sr.s_suppkey
    GROUP BY sr.p_partkey, s.s_suppkey, s.s_name
)
SELECT n.n_name, r.r_name, rs.s_name, rs.aggregate_cost
FROM RankedSuppliers rs
JOIN supplier s ON rs.s_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE rs.supplier_rank <= 3
ORDER BY r.r_name, n.n_name, rs.aggregate_cost DESC;
