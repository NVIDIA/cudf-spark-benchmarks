WITH SupplierStats AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyValue,
           COUNT(DISTINCT p.p_partkey) AS PartCount
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT c.c_custkey,
           c.c_name,
           SUM(o.o_totalprice) AS TotalOrderValue,
           COUNT(o.o_orderkey) AS OrderCount
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= (cast('1998-10-01' as date) - INTERVAL '1 year')
    GROUP BY c.c_custkey, c.c_name
),
RankedSuppliers AS (
    SELECT s.*, 
           RANK() OVER (ORDER BY TotalSupplyValue DESC) AS SupplyRank
    FROM SupplierStats s
),
RankedCustomers AS (
    SELECT c.*, 
           RANK() OVER (ORDER BY TotalOrderValue DESC) AS OrderRank
    FROM CustomerOrders c
)

SELECT rs.s_suppkey, 
       rs.s_name AS SupplierName, 
       rc.c_custkey, 
       rc.c_name AS CustomerName,
       rs.TotalSupplyValue, 
       rc.TotalOrderValue
FROM RankedSuppliers rs
JOIN RankedCustomers rc ON rs.SupplyRank = rc.OrderRank
WHERE rs.SupplyRank <= 10 AND rc.OrderRank <= 10
ORDER BY rs.TotalSupplyValue DESC, rc.TotalOrderValue DESC;