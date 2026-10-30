WITH RecursivePart AS (
    SELECT p_partkey, p_name, 
           CASE 
               WHEN p_size IS NULL THEN 'UNKNOWN' 
               ELSE 
                   CASE 
                       WHEN p_size < 10 THEN 'SMALL'
                       WHEN p_size BETWEEN 10 AND 20 THEN 'MEDIUM'
                       ELSE 'LARGE' 
                   END 
           END AS size_category,
           ROW_NUMBER() OVER (PARTITION BY p_brand ORDER BY p_retailprice DESC) AS brand_rank
    FROM part
),
TotalSales AS (
    SELECT l_partkey, 
           SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
    FROM lineitem
    WHERE l_shipdate >= '1997-01-01' OR l_discount IS NOT NULL
    GROUP BY l_partkey
),
SupplierDetails AS (
    SELECT s_nationkey, 
           SUM(s_acctbal) AS total_acctbal,
           COUNT(s_suppkey) AS supplier_count
    FROM supplier
    GROUP BY s_nationkey
),
CustomerPerformance AS (
    SELECT c.c_custkey,
           COUNT(o.o_orderkey) AS order_count,
           AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL
    GROUP BY c.c_custkey
)
SELECT 
    rp.p_name,
    rp.size_category,
    COALESCE(ts.total_revenue, 0) AS total_revenue,
    COALESCE(sd.total_acctbal, 0) AS supplier_acctbal,
    cp.order_count,
    cp.avg_order_value,
    RANK() OVER (PARTITION BY rp.size_category ORDER BY COALESCE(ts.total_revenue, 0) DESC) AS revenue_rank
FROM RecursivePart rp
LEFT JOIN TotalSales ts ON rp.p_partkey = ts.l_partkey
LEFT JOIN SupplierDetails sd ON rp.p_partkey = sd.s_nationkey
LEFT JOIN CustomerPerformance cp ON rp.p_partkey = cp.c_custkey 
WHERE rp.brand_rank <= 5 AND cp.order_count IS NOT NULL
ORDER BY rp.size_category, total_revenue DESC;