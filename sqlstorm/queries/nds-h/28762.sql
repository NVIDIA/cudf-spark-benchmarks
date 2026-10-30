
WITH SupplierParts AS (
    SELECT s.s_name, p.p_name, ps.ps_supplycost, ps.ps_availqty,
           ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ps.ps_supplycost DESC) AS rn
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
TopSuppliers AS (
    SELECT s.s_nationkey, SUM(sp.ps_supplycost * sp.ps_availqty) AS total_cost
    FROM SupplierParts sp
    JOIN supplier s ON sp.s_name = s.s_name
    WHERE sp.rn <= 5
    GROUP BY s.s_nationkey
),
NationSummary AS (
    SELECT n.n_name, n.n_regionkey, ts.total_cost
    FROM nation n
    JOIN TopSuppliers ts ON n.n_nationkey = ts.s_nationkey
)
SELECT r.r_name, SUM(ns.total_cost) AS total_cost_per_region, COUNT(*) AS num_nations
FROM region r
JOIN NationSummary ns ON r.r_regionkey = ns.n_regionkey
GROUP BY r.r_name
ORDER BY total_cost_per_region DESC;
