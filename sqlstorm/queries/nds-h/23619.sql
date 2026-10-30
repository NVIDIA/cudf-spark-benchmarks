WITH  CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice, o.o_orderdate,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
),
PartSuppliers AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_avail_qty,
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
HighValueOrders AS (
    SELECT co.c_custkey, SUM(co.o_totalprice) AS total_spent
    FROM CustomerOrders co
    WHERE co.rn <= 5
    GROUP BY co.c_custkey
    HAVING SUM(co.o_totalprice) > 10000
),
RelevantSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 5000
),
PostProcessing AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, COALESCE(ps.total_avail_qty, 0) AS avail_qty,
           ps.supplier_count, COALESCE(hvo.total_spent, 0) AS total_spent
    FROM part p
    LEFT JOIN PartSuppliers ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN HighValueOrders hvo ON hvo.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_name LIKE '%Acme%')
)
SELECT DISTINCT pp.p_partkey, pp.p_name, pp.p_retailprice, pp.avail_qty, pp.supplier_count, pp.total_spent,
       CASE 
           WHEN pp.total_spent > 0 THEN 'High Value'
           ELSE 'Regular'
       END AS customer_value_category
FROM PostProcessing pp
INNER JOIN RelevantSuppliers rs ON pp.supplier_count > 1
WHERE pp.avail_qty > (SELECT AVG(avail_qty) FROM PostProcessing) 
  AND (pp.p_retailprice - pp.total_spent) < 1000
ORDER BY pp.total_spent DESC, pp.p_retailprice DESC
LIMIT 5 OFFSET 10;
