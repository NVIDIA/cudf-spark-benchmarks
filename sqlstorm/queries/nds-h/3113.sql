WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY s.s_suppkey, s.s_name
),
CustomerRegion AS (
    SELECT 
        c.c_custkey,
        r.r_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS orders_count
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, r.r_name
),
SalesRank AS (
    SELECT 
        s.s_name,
        s.total_sales,
        RANK() OVER (ORDER BY s.total_sales DESC) AS sales_rank
    FROM SupplierSales s
),
CustomerRank AS (
    SELECT 
        cr.r_name,
        cr.total_spent,
        DENSE_RANK() OVER (ORDER BY cr.total_spent DESC) AS customer_rank
    FROM CustomerRegion cr
)
SELECT 
    sr.s_name,
    sr.total_sales,
    cr.r_name,
    cr.total_spent
FROM SalesRank sr
FULL OUTER JOIN CustomerRank cr ON sr.sales_rank = cr.customer_rank
WHERE (sr.total_sales IS NOT NULL AND cr.total_spent IS NOT NULL)
   OR (sr.total_sales IS NULL AND cr.total_spent IS NULL)
ORDER BY sr.total_sales DESC NULLS LAST, cr.total_spent DESC NULLS LAST;
