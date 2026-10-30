WITH  sales_summary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_sales,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= (cast('1998-10-01' as date) - INTERVAL '1 year')
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 5000
),
part_supplier AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COUNT(ps.ps_suppkey) AS supplier_count,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
customer_nation AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        n.n_name
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
),
ranked_sales AS (
    SELECT 
        ss.c_custkey,
        ss.c_name,
        ss.total_sales,
        ss.order_count,
        ROW_NUMBER() OVER (ORDER BY ss.total_sales DESC) AS sales_rank,
        COALESCE(CAST(NULLIF(ss.total_sales, 0) AS DECIMAL(12,2)), 0) AS adjusted_sales
    FROM 
        sales_summary ss
)
SELECT 
    cs.c_name,
    cs.n_name AS customer_nation,
    ps.p_name,
    ps.supplier_count,
    ps.avg_supplycost,
    rs.total_sales,
    rs.order_count,
    rs.sales_rank
FROM 
    customer_nation cs
JOIN 
    ranked_sales rs ON cs.c_custkey = rs.c_custkey
LEFT JOIN 
    part_supplier ps ON rs.total_sales > ps.avg_supplycost
WHERE 
    cs.n_name IN (SELECT r.r_name FROM region r WHERE r.r_comment LIKE '%important%')
ORDER BY 
    rs.sales_rank, ps.avg_supplycost DESC
LIMIT 50;