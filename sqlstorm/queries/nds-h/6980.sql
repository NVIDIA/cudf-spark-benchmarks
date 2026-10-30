WITH NationSupplier AS (
    SELECT n.n_name, s.s_suppkey, s.s_acctbal, s.s_comment
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
PartSupplier AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, ps.ps_supplycost
    FROM partsupp ps
    WHERE ps.ps_availqty > 100
),
TopParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice
    FROM part p
    JOIN PartSupplier ps ON p.p_partkey = ps.ps_partkey
    ORDER BY p.p_retailprice DESC
    LIMIT 10
)
SELECT ns.n_name AS Supplier_Nation, tp.p_name AS Top_Part, ps.ps_supplycost AS Supplier_Cost, ns.s_acctbal AS Supplier_Balance
FROM NationSupplier ns
JOIN PartSupplier ps ON ns.s_suppkey = ps.ps_suppkey
JOIN TopParts tp ON ps.ps_partkey = tp.p_partkey
ORDER BY ns.n_name, ps.ps_supplycost DESC;
