WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           RANK() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS cost_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
TopSuppliers AS (
    SELECT r.r_name, ns.n_name, rs.s_suppkey, rs.s_name, rs.s_acctbal
    FROM RankedSuppliers rs
    JOIN nation ns ON rs.s_suppkey = ns.n_nationkey
    JOIN region r ON ns.n_regionkey = r.r_regionkey
    WHERE rs.cost_rank <= 5
)
SELECT t.r_name, 
       COUNT(DISTINCT t.s_suppkey) AS supplier_count, 
       SUM(t.s_acctbal) AS total_acctbal, 
       AVG(t.s_acctbal) AS avg_acctbal
FROM TopSuppliers t
GROUP BY t.r_name
ORDER BY total_acctbal DESC
LIMIT 10;
