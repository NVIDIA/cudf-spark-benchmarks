
WITH RecursivePart AS (
    SELECT p_partkey, p_name, p_brand, p_size,
           ROW_NUMBER() OVER (PARTITION BY p_brand ORDER BY p_retailprice DESC) AS price_rank
    FROM part
    WHERE p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice > 1000)
),
HighValueSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_comment IS NOT NULL)
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 50000
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderstatus,
           CASE 
               WHEN o.o_orderstatus = 'O' THEN 'Open'
               WHEN o.o_orderstatus = 'F' THEN 'Finished'
               ELSE 'Other' 
           END AS order_status
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > 0
      AND o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
)
SELECT DISTINCT 
    rp.p_name, 
    rp.p_brand,
    rp.p_size,
    co.order_status,
    COALESCE(AVG(l.l_discount), 0) AS avg_discount,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count
FROM RecursivePart rp
LEFT JOIN lineitem l ON l.l_partkey = rp.p_partkey
LEFT JOIN HighValueSuppliers s ON l.l_suppkey = s.s_suppkey
LEFT JOIN CustomerOrders co ON co.o_orderkey = l.l_orderkey
WHERE rp.price_rank <= 3
  AND (COALESCE(l.l_returnflag, 'N') = 'N' OR l.l_linestatus = 'F')
GROUP BY rp.p_name, rp.p_brand, rp.p_size, co.order_status
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY total_revenue DESC, rp.p_name;
