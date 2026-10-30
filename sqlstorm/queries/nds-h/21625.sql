
WITH RankedOrders AS (
    SELECT o.o_orderkey,
           o.o_orderdate,
           o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
),
FilteredSuppliers AS (
    SELECT s.s_suppkey,
           s.s_name,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 0
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > (
        SELECT AVG(total_supplycost)
        FROM (SELECT SUM(ps_supplycost * ps_availqty) AS total_supplycost
              FROM partsupp ps
              GROUP BY ps.ps_suppkey) AS avg_supplycosts
    )
),
CustomerOrderDetails AS (
    SELECT c.c_custkey,
           c.c_name,
           COALESCE(SUM(o.o_totalprice), 0) AS total_order_value,
           COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey 
    GROUP BY c.c_custkey, c.c_name
    HAVING COUNT(o.o_orderkey) > 0
),
PartSupplierDetails AS (
    SELECT p.p_partkey,
           p.p_name,
           p.p_retailprice,
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_retailprice
    HAVING COUNT(DISTINCT ps.ps_suppkey) > 1
)
SELECT cd.c_custkey,
       cd.c_name,
       cd.total_order_value,
       psd.p_partkey,
       psd.p_name,
       psd.p_retailprice,
       psd.supplier_count,
       r.r_name AS region_name
FROM CustomerOrderDetails cd
JOIN nation n ON cd.c_custkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
JOIN PartSupplierDetails psd ON cd.order_count > 5 AND psd.supplier_count > 2
WHERE cd.total_order_value BETWEEN 500 AND 10000
  AND psd.p_retailprice > (SELECT AVG(p.p_retailprice) FROM part p)
ORDER BY cd.total_order_value DESC, psd.p_retailprice
LIMIT 10 OFFSET 5;
