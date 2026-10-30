WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, n.n_name AS nation_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name
),
FilteredSuppliers AS (
    SELECT s.*, RANK() OVER (PARTITION BY nation_name ORDER BY total_value DESC) AS rank
    FROM RankedSuppliers s
    WHERE total_value > 100000
),
TopSuppliers AS (
    SELECT * FROM FilteredSuppliers WHERE rank <= 5
)
SELECT p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_size, p.p_retailprice, ts.s_name, ts.nation_name
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN TopSuppliers ts ON ps.ps_suppkey = ts.s_suppkey
WHERE p.p_retailprice > 50 AND p.p_size < 20
ORDER BY ts.nation_name, p.p_retailprice DESC;
