
WITH FilteredParts AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_type, p.p_retailprice, p.p_comment
    FROM part p
    WHERE LENGTH(p.p_name) > 10 AND p.p_retailprice < 50
),
SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_comment
    FROM supplier s
    WHERE s.s_acctbal > 1000 AND s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name LIKE 'A%')
),
CustomerOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    AND EXTRACT(YEAR FROM o.o_orderdate) = 1997
)
SELECT 
    fp.p_partkey,
    fp.p_name,
    fp.p_brand,
    COUNT(DISTINCT li.l_orderkey) AS total_orders,
    SUM(co.o_totalprice) AS total_revenue
FROM FilteredParts fp
JOIN lineitem li ON li.l_partkey = fp.p_partkey
JOIN CustomerOrders co ON li.l_orderkey = co.o_orderkey
JOIN SupplierDetails sd ON li.l_suppkey = sd.s_suppkey
GROUP BY fp.p_partkey, fp.p_name, fp.p_brand
ORDER BY total_revenue DESC
LIMIT 10;
