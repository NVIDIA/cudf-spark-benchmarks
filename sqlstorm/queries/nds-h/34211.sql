WITH  SupplierRanking AS (
    SELECT s_suppkey, s_name, s_acctbal, ROW_NUMBER() OVER (ORDER BY s_acctbal DESC) AS rank
    FROM supplier
), 
HighValueParts AS (
    SELECT p_partkey, p_name, p_retailprice
    FROM part
    WHERE p_retailprice > (
        SELECT AVG(p_retailprice) 
        FROM part
    )
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING COUNT(o.o_orderkey) > 0
)
SELECT 
    r.r_name,
    SUM(COALESCE(l.l_extendedprice, 0)) AS total_sales,
    COUNT(DISTINCT co.c_custkey) AS active_customers,
    COUNT(DISTINCT sr.s_suppkey) AS top_suppliers
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey 
LEFT JOIN HighValueParts p ON ps.ps_partkey = p.p_partkey
LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN CustomerOrders co ON co.c_custkey = l.l_orderkey
LEFT JOIN SupplierRanking sr ON s.s_suppkey = sr.s_suppkey AND sr.rank <= 5
WHERE p.p_partkey IS NOT NULL
GROUP BY r.r_name
ORDER BY total_sales DESC
LIMIT 10;
