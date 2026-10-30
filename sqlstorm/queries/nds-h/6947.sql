WITH NationStats AS (
    SELECT 
        n.n_name, 
        COUNT(DISTINCT c.c_custkey) AS customer_count, 
        SUM(o.o_totalprice) AS total_sales, 
        SUM(l.l_quantity) AS total_quantity
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    GROUP BY 
        n.n_name
),
TopNations AS (
    SELECT 
        n_name, 
        customer_count, 
        total_sales, 
        total_quantity,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        NationStats
)
SELECT 
    n.n_name,
    n.customer_count,
    n.total_sales,
    n.total_quantity,
    CASE 
        WHEN sales_rank <= 5 THEN 'Top Nation'
        ELSE 'Other'
    END AS nation_category
FROM 
    TopNations n
ORDER BY 
    n.total_sales DESC, 
    n.n_name;
