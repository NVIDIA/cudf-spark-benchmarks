WITH SupplierParts AS (
    SELECT s.s_suppkey, s.s_name, p.p_partkey, p.p_name, ps.ps_supplycost, ps.ps_availqty
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
), 
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
), 
OrderLineItems AS (
    SELECT ol.l_orderkey, ol.l_partkey, ol.l_quantity, ol.l_extendedprice, ol.l_discount, ol.l_tax
    FROM lineitem ol
), 
TotalSales AS (
    SELECT co.c_custkey, co.c_name, SUM(ol.l_extendedprice * (1 - ol.l_discount)) AS total_sales
    FROM CustomerOrders co
    JOIN OrderLineItems ol ON co.o_orderkey = ol.l_orderkey
    GROUP BY co.c_custkey, co.c_name
)
SELECT sp.s_name, p.p_name, sp.ps_supplycost, sp.ps_availqty, ts.c_name, ts.total_sales
FROM SupplierParts sp
JOIN TotalSales ts ON ts.c_custkey = (
    SELECT c.c_custkey 
    FROM customer c 
    ORDER BY c.c_acctbal DESC 
    LIMIT 1
)
JOIN part p ON sp.p_partkey = p.p_partkey
WHERE sp.ps_availqty > 0
ORDER BY ts.total_sales DESC, sp.ps_supplycost ASC
LIMIT 10;
