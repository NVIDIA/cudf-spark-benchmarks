WITH  regional_sales AS (
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
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        r.r_name, r.r_regionkey
),
top_sales AS (
    SELECT 
        region_name,
        total_sales
    FROM 
        regional_sales
    WHERE 
        sales_rank <= 3
),
customer_order_count AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    c.c_name AS customer_name,
    COALESCE(order_count, 0) AS number_of_orders,
    ts.region_name,
    ts.total_sales
FROM 
    customer c
LEFT JOIN 
    customer_order_count coc ON c.c_custkey = coc.c_custkey
LEFT JOIN 
    top_sales ts ON ts.region_name = (
        SELECT 
            r_name 
        FROM 
            region 
        WHERE 
            r_regionkey IN (
                SELECT 
                    n.n_regionkey 
                FROM 
                    nation n 
                JOIN 
                    supplier s ON n.n_nationkey = s.s_nationkey 
                WHERE 
                    s.s_suppkey = (
                        SELECT 
                            ps.ps_suppkey 
                        FROM 
                            partsupp ps 
                        JOIN 
                            lineitem l ON ps.ps_partkey = l.l_partkey 
                        GROUP BY 
                            ps.ps_suppkey 
                        ORDER BY 
                            SUM(l.l_extendedprice) DESC 
                        LIMIT 1
                    )
            )
    )
ORDER BY 
    ts.total_sales DESC NULLS LAST, 
    c.c_name;
