
WITH SupplierParts AS (
    SELECT s.s_suppkey, s.s_name, p.p_partkey, p.p_name, p.p_brand, p.p_type, 
           p.p_size, ps.ps_availqty, ps.ps_supplycost, ps.ps_comment
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderstatus, 
           o.o_totalprice, o.o_orderdate, o.o_orderpriority, o.o_comment
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_retailprice, 
           COUNT(l.l_orderkey) AS order_count, 
           SUM(l.l_quantity) AS total_quantity
    FROM part p
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand, p.p_retailprice
)
SELECT sp.s_name, sp.p_name, sp.p_brand, sp.p_type, sp.p_size, 
       co.c_name AS customer_name, co.o_orderdate, co.o_orderstatus, 
       pd.order_count, pd.total_quantity, sp.ps_supplycost, 
       CONCAT('Supplier: ', sp.s_name, ', Product: ', sp.p_name, 
              ' (', sp.p_type, ') - Orders: ', pd.order_count) AS summary
FROM SupplierParts sp
JOIN CustomerOrders co ON sp.s_suppkey = co.c_custkey
JOIN PartDetails pd ON sp.p_partkey = pd.p_partkey
WHERE sp.ps_availqty > 0
  AND co.o_orderstatus = 'O'
  AND pd.total_quantity > 10
ORDER BY sp.p_brand, sp.p_name, co.o_orderdate DESC
LIMIT 100;
