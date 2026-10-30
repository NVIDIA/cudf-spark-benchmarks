
WITH  RegionalSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY r.r_regionkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        r.r_regionkey, r.r_name
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS spending_rank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    r.region_name,
    COALESCE(cs.c_name, 'No Orders') AS customer_name,
    cs.order_count,
    cs.total_spent,
    COALESCE(r.total_sales, 0) AS region_sales,
    CASE 
        WHEN cs.order_count IS NULL THEN 'No Orders'
        WHEN cs.total_spent > r.total_sales THEN 'Over budget'
        ELSE 'Within budget'
    END AS budget_status
FROM 
    RegionalSales r
FULL OUTER JOIN 
    CustomerOrderStats cs ON r.region_name = SUBSTRING(cs.c_name, 1, LENGTH(r.region_name))
WHERE 
    (r.total_sales IS NOT NULL OR cs.order_count IS NOT NULL)
ORDER BY 
    r.region_name, cs.spending_rank;
