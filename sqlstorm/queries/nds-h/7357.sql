WITH TotalSuppliers AS (
    SELECT ps.ps_partkey, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey
),
HighPriceParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice
    FROM part p
    WHERE p.p_retailprice > (SELECT AVG(p_retailprice) FROM part)
),
PartSupplierInfo AS (
    SELECT p.p_partkey, p.p_name, ts.supplier_count, p.p_retailprice
    FROM TotalSuppliers ts
    JOIN HighPriceParts hp ON ts.ps_partkey = hp.p_partkey
    JOIN part p ON p.p_partkey = hp.p_partkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= DATE '1997-01-01'
)
SELECT psi.p_name, psi.supplier_count, co.c_name, co.o_orderkey, co.o_totalprice
FROM PartSupplierInfo psi
JOIN CustomerOrders co ON psi.supplier_count > 5
ORDER BY psi.supplier_count DESC, co.o_totalprice DESC
LIMIT 10;