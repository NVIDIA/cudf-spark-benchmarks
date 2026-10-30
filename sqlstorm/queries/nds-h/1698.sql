
WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
           RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS RankInRegion
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY s.s_suppkey, s.s_name, n.n_regionkey
)
SELECT c.c_name AS CustomerName, 
       SUM(o.o_totalprice) AS TotalOrderCost,
       COUNT(DISTINCT o.o_orderkey) AS TotalOrders,
       COALESCE(MAX(rs.TotalSupplyCost), 0) AS MaxSupplierCost
FROM customer c
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN RankedSuppliers rs ON rs.s_suppkey = (
    SELECT ps.ps_suppkey 
    FROM partsupp ps 
    JOIN part p ON ps.ps_partkey = p.p_partkey 
    WHERE p.p_size > 10
    AND p.p_retailprice < (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_type = p.p_type)
    LIMIT 1
)
GROUP BY c.c_name
HAVING SUM(o.o_totalprice) > (
    SELECT AVG(o2.o_totalprice) 
    FROM orders o2 
    WHERE o2.o_orderstatus = 'F'
)
ORDER BY TotalOrderCost DESC;
