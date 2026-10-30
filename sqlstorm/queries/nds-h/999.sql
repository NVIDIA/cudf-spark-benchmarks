
WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           ROW_NUMBER() OVER (ORDER BY c.c_acctbal DESC) AS customer_rank
    FROM customer c
    WHERE c.c_acctbal > 1000
)
SELECT o.o_orderkey, o.o_orderstatus, o.o_totalprice,
       COALESCE(s.s_name, 'No Supplier') AS supplier_name,
       COALESCE(c.c_name, 'No Customer') AS customer_name,
       l.l_quantity, l.l_extendedprice * (1 - l.l_discount) AS net_price,
       CONCAT(l.l_shipmode, ' - ', l.l_returnflag) AS shipping_info
FROM orders o
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN RankedSuppliers s ON s.supplier_rank = 1 AND l.l_suppkey = s.s_suppkey
LEFT JOIN HighValueCustomers c ON o.o_custkey = c.c_custkey
WHERE o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
  AND (l.l_discount IS NULL OR l.l_discount < 0.2)
ORDER BY o.o_orderkey, net_price DESC
LIMIT 100;
