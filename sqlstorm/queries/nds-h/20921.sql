WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
),
AvailableParts AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, 
           pp.p_mfgr, pp.p_brand,
           CASE 
               WHEN pp.p_retailprice IS NULL THEN 0 
               ELSE pp.p_retailprice 
           END AS adjusted_price
    FROM partsupp ps
    JOIN part pp ON ps.ps_partkey = pp.p_partkey
    WHERE ps.ps_availqty > 0 
),
CustomerOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey, o.o_custkey, o.o_orderdate
),
NationRegion AS (
    SELECT n.n_nationkey, n.n_name, r.r_regionkey, r.r_name
    FROM nation n
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT crn.n_name AS nation_name,
       SUM(ap.adjusted_price * ap.ps_availqty) AS total_available_value,
       COUNT(DISTINCT co.o_orderkey) AS total_orders,
       AVG(co.total_order_value) AS avg_order_value,
       MAX(rs.s_acctbal) AS max_supplier_balance,
       CASE 
           WHEN SUM(ap.ps_availqty) > 1000 THEN 'High Availability'
           ELSE 'Low Availability' 
       END AS availability_status
FROM AvailableParts ap
JOIN RankedSuppliers rs ON ap.ps_suppkey = rs.s_suppkey
JOIN CustomerOrders co ON co.o_custkey IN (
    SELECT c.c_custkey 
    FROM customer c 
    WHERE c.c_acctbal > 1000 AND c.c_mktsegment = 'BUILDING'
)
JOIN NationRegion crn ON rs.s_suppkey = crn.n_nationkey
WHERE rs.rank = 1
GROUP BY crn.n_name
HAVING MAX(rs.s_acctbal) IS NOT NULL 
   AND COUNT(DISTINCT co.o_orderkey) > 10
ORDER BY total_orders DESC, avg_order_value ASC;
