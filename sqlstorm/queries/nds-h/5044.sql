
WITH SupplierInfo AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > 10000
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_retailprice, ps.ps_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_size BETWEEN 10 AND 20
),
CustomerOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, c.c_name AS customer_name
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= '1997-01-01'
)
SELECT 
    CO.customer_name,
    ps.p_name,
    ps.p_brand,
    SUM(li.l_quantity) AS total_quantity,
    SUM(li.l_extendedprice) AS total_revenue,
    AVG(SI.s_acctbal) AS avg_supplier_acctbal,
    COUNT(DISTINCT COALESCE(SI.s_suppkey, 0)) AS unique_suppliers
FROM lineitem li
JOIN CustomerOrders CO ON li.l_orderkey = CO.o_orderkey
JOIN PartDetails ps ON li.l_partkey = ps.p_partkey
LEFT JOIN SupplierInfo SI ON li.l_suppkey = SI.s_suppkey
GROUP BY CO.customer_name, ps.p_name, ps.p_brand
HAVING SUM(li.l_quantity) > 100
ORDER BY total_revenue DESC
LIMIT 50;
