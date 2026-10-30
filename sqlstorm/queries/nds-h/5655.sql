WITH SupplierParts AS (
    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, p.p_name, 
           ps.ps_availqty, ps.ps_supplycost, p.p_retailprice, 
           (ps.ps_supplycost * ps.ps_availqty) AS TotalCost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, 
           o.o_orderdate, o.o_totalprice, 
           o.o_orderstatus, o.o_orderpriority
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O' AND o.o_orderdate >= '1997-01-01'
),
AggregatedData AS (
    SELECT co.c_custkey, co.c_name, 
           SUM(sp.TotalCost) AS TotalSupplierCost, 
           COUNT(co.o_orderkey) AS OrderCount,
           SUM(co.o_totalprice) AS TotalOrderValue
    FROM CustomerOrders co
    JOIN SupplierParts sp ON co.o_orderkey = sp.ps_partkey
    GROUP BY co.c_custkey, co.c_name
)
SELECT ad.c_custkey, ad.c_name, ad.TotalSupplierCost, 
       ad.OrderCount, ad.TotalOrderValue
FROM AggregatedData ad
WHERE ad.TotalSupplierCost > 1000000
ORDER BY ad.TotalOrderValue DESC
LIMIT 10;