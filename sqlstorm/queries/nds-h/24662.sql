WITH RECURSIVE RecursiveSupplier AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal
    FROM supplier s
    INNER JOIN RecursiveSupplier rs ON s.s_nationkey = rs.s_nationkey
    WHERE s.s_acctbal < rs.s_acctbal
),
AvailableParts AS (
    SELECT p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rn
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE ps.ps_availqty > 0
),
HighValueOrders AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS HighValue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey 
    WHERE l.l_returnflag = 'N'
    GROUP BY o.o_orderkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
)
SELECT DISTINCT
    ns.n_name AS Nation_Name,
    p.p_name AS Part_Name,
    COALESCE(SUM(ps.ps_availqty), 0) AS Total_Available,
    AVG(ps.ps_supplycost) AS Average_Supply_Cost,
    (SELECT COUNT(*) FROM HighValueOrders) AS Total_High_Value_Orders
FROM region r
LEFT JOIN nation ns ON r.r_regionkey = ns.n_regionkey
LEFT JOIN supplier s ON ns.n_nationkey = s.s_nationkey
LEFT JOIN AvailableParts p ON s.s_suppkey = p.p_partkey
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
WHERE r.r_name IS NOT NULL AND (ns.n_name LIKE 'A%' OR ns.n_name IS NULL)
GROUP BY ns.n_name, p.p_name
HAVING COUNT(DISTINCT s.s_suppkey) > 1 OR COUNT(p.p_partkey) = 0
ORDER BY Nation_Name, Part_Name DESC
LIMIT 10;

