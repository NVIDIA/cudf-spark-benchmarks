WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name,
           ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name
    FROM RankedSuppliers s
    JOIN nation n ON s.nation_name = n.n_name
    WHERE s.rn <= 5
),
SupplierParts AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, p.p_name, p.p_retailprice, p.p_brand,
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE ps.ps_supplycost < (SELECT AVG(ps_supplycost) FROM partsupp)
    GROUP BY ps.ps_partkey, ps.ps_suppkey, p.p_name, p.p_retailprice, p.p_brand
),
TopParts AS (
    SELECT sp.ps_partkey, sp.p_name, sp.p_retailprice, sp.p_brand
    FROM SupplierParts sp
    JOIN TopSuppliers ts ON sp.ps_suppkey = ts.s_suppkey
    WHERE sp.supplier_count > 1
)
SELECT tp.p_name, tp.p_retailprice, COUNT(DISTINCT ts.s_suppkey) AS num_suppliers,
       SUM(l.l_quantity) AS total_quantity_sold
FROM TopParts tp
JOIN lineitem l ON l.l_partkey = tp.ps_partkey
JOIN TopSuppliers ts ON ts.s_suppkey = l.l_suppkey
WHERE l.l_shipdate >= DATE '1996-01-01' AND l.l_shipdate < DATE '1997-01-01'
GROUP BY tp.p_name, tp.p_retailprice
ORDER BY total_quantity_sold DESC;