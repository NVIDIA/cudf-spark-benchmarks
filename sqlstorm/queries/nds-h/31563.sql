WITH  CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O' AND o.o_totalprice > 1000
),
SupplierParts AS (
    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, ps.ps_availqty,
           ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ps.ps_supplycost DESC) AS rn
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty > 0
),
MostOrderedParts AS (
    SELECT l.l_partkey, SUM(l.l_quantity) AS total_quantity
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderdate >= cast('1998-10-01' as date) - INTERVAL '1 year' 
    GROUP BY l.l_partkey
    HAVING SUM(l.l_quantity) > 500
),
AggregateInfo AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_retailprice,
           COALESCE(p_total.total_quantity, 0) AS total_ordered,
           COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name,
           ROW_NUMBER() OVER (ORDER BY COALESCE(p_total.total_quantity, 0) DESC) AS rn
    FROM part p
    LEFT JOIN MostOrderedParts p_total ON p.p_partkey = p_total.l_partkey
    LEFT JOIN SupplierParts s ON p.p_partkey = s.ps_partkey
)
SELECT a.p_partkey, a.p_name, a.p_brand, a.p_retailprice, a.total_ordered, a.supplier_name
FROM AggregateInfo a
WHERE a.total_ordered > 0 AND a.rn <= 10
ORDER BY a.total_ordered DESC, a.p_retailprice ASC;