WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000
),
HighValueParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, 
           CASE 
               WHEN p.p_retailprice > 1000 THEN 'Expensive'
               WHEN p.p_retailprice BETWEEN 500 AND 1000 THEN 'Moderate'
               ELSE 'Cheap' 
           END AS price_category
    FROM part p
    WHERE p.p_retailprice IS NOT NULL
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING COUNT(o.o_orderkey) > 5
)
SELECT co.c_name AS Customer_Name,
       hp.p_name AS Part_Name,
       hs.s_name AS Supplier_Name,
       hp.price_category,
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS Total_Sales,
       RANK() OVER (PARTITION BY hp.price_category ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS Sales_Rank
FROM lineitem l
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN CustomerOrders co ON o.o_custkey = co.c_custkey
JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN HighValueParts hp ON ps.ps_partkey = hp.p_partkey
JOIN RankedSuppliers hs ON ps.ps_suppkey = hs.s_suppkey
WHERE l.l_returnflag = 'N'
      AND l.l_shipdate BETWEEN '1996-01-01' AND '1997-12-31'
      AND hp.price_category IN ('Expensive', 'Moderate')
GROUP BY co.c_name, hp.p_name, hs.s_name, hp.price_category
ORDER BY Sales_Rank, Total_Sales DESC
LIMIT 10;