WITH SupplierInfo AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
),
PartSuppliers AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, ps.ps_supplycost,
           PERCENT_RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost) AS cost_rank
    FROM partsupp ps
    WHERE ps.ps_availqty > 50
),
FilteredParts AS (
    SELECT p.p_partkey, p.p_name, p.p_type, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM part p
    JOIN PartSuppliers ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_type
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 1000
),
NationStats AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT n.n_name, fp.p_name, fp.total_supply_cost, si.s_name, si.s_acctbal
FROM FilteredParts fp
JOIN SupplierInfo si ON si.rank = 1
JOIN nation n ON si.s_nationkey = n.n_nationkey
WHERE n.n_nationkey IN (SELECT n_nationkey FROM nationstats WHERE supplier_count > 10)
ORDER BY fp.total_supply_cost DESC, n.n_name, si.s_acctbal DESC
LIMIT 100;
