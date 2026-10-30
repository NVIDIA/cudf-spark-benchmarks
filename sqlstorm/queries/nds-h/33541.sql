
WITH  CTE_Supplier_Part AS (
    SELECT p.p_partkey, p.p_name, p.p_mfgr, p.p_retailprice, ps.ps_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal IS NOT NULL
),
CTE_Aggregated AS (
    SELECT p_partkey, SUM(p_retailprice) AS total_retail_price
    FROM CTE_Supplier_Part
    WHERE rank = 1
    GROUP BY p_partkey
),
CTE_Nation_Orders AS (
    SELECT n.n_name, COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN customer c ON s.s_suppkey = c.c_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY n.n_name
)
SELECT r.r_name, 
       COALESCE(a.total_retail_price, 0) AS total_retail_price,
       COALESCE(n.order_count, 0) AS order_count
FROM region r
LEFT JOIN CTE_Aggregated a ON r.r_regionkey = (
    SELECT n.n_regionkey 
    FROM nation n 
    WHERE n.n_name = 'UNITED STATES'
)
LEFT JOIN CTE_Nation_Orders n ON n.n_name = r.r_name
ORDER BY r.r_name;
