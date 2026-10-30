WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, n.n_name AS nation_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name
), FilteredSuppliers AS (
    SELECT r.*, ROW_NUMBER() OVER (PARTITION BY nation_name ORDER BY total_supply_cost DESC) AS rank
    FROM RankedSuppliers r
    WHERE total_supply_cost > (SELECT AVG(total_supply_cost) FROM RankedSuppliers)
)
SELECT p.p_partkey, p.p_name, f.s_name AS supplier_name, f.nation_name, f.total_supply_cost
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN FilteredSuppliers f ON ps.ps_suppkey = f.s_suppkey
WHERE p.p_size BETWEEN 10 AND 50
ORDER BY p.p_partkey, f.total_supply_cost DESC
LIMIT 100;
