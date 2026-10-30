WITH  SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(li.l_extendedprice * (1 - li.l_discount)) DESC) AS sales_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem li ON p.p_partkey = li.l_partkey
    WHERE 
        li.l_shipdate >= '1997-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(li.l_extendedprice * (1 - li.l_discount)) > 10000
),
FilteredAggregates AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        total_sales,
        CASE 
            WHEN total_sales > 100000 THEN 'High'
            WHEN total_sales BETWEEN 50000 AND 100000 THEN 'Medium'
            ELSE 'Low'
        END AS sales_category
    FROM 
        SupplierSales s
    WHERE 
        sales_rank = 1
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) IS NOT NULL
)
SELECT 
    r.r_name,
    fa.sales_category,
    SUM(c.order_count) AS total_orders,
    AVG(c.total_spent) AS avg_spent_per_customer
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    FilteredAggregates fa ON s.s_suppkey = fa.s_suppkey
LEFT JOIN 
    CustomerOrders c ON c.c_custkey IN (
        SELECT 
            DISTINCT o.o_custkey
        FROM 
            orders o
        JOIN 
            lineitem li ON o.o_orderkey = li.l_orderkey
        WHERE 
            li.l_returnflag = 'R'
    )
GROUP BY 
    r.r_name, fa.sales_category
ORDER BY 
    r.r_name, fa.sales_category DESC;