WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_name, ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY o.o_totalprice DESC) AS rnk
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderstatus = 'F'
),
SupplierPartDetails AS (
    SELECT ps.ps_partkey, s.s_name, s.s_acctbal, p.p_name, SUM(ps.ps_availqty) AS total_available
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY ps.ps_partkey, s.s_name, s.s_acctbal, p.p_name
),
QualifiedParts AS (
    SELECT pp.p_partkey, pp.p_name, pp.p_brand, pp.p_retailprice
    FROM (
        SELECT p.*
        FROM part p
        WHERE p.p_size BETWEEN 10 AND 20
        AND p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
    ) pp
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice,
    ro.c_name,
    spd.s_name AS supplier_name,
    spd.total_available,
    qp.p_name AS part_name,
    qp.p_brand,
    qp.p_retailprice
FROM RankedOrders ro
JOIN SupplierPartDetails spd ON ro.o_orderkey = spd.ps_partkey
JOIN QualifiedParts qp ON spd.ps_partkey = qp.p_partkey
WHERE ro.rnk <= 10
ORDER BY ro.o_totalprice DESC, spd.total_available DESC;
