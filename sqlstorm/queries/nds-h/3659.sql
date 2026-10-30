
WITH regional_sales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        r.r_name
), 
top_customers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        ROW_NUMBER() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > (
            SELECT AVG(o2.o_totalprice) 
            FROM orders o2 
            WHERE o2.o_orderstatus = 'F'
        )
),
final_report AS (
    SELECT 
        rs.region_name,
        COALESCE(tc.c_name, 'No Customer') AS customer_name,
        rs.total_sales,
        tc.total_spent
    FROM 
        regional_sales rs
    FULL OUTER JOIN 
        top_customers tc ON rs.region_name LIKE '%' || SUBSTRING(tc.c_name FROM 1 FOR 5) || '%'
)
SELECT 
    fr.region_name,
    fr.customer_name,
    fr.total_sales,
    fr.total_spent,
    CASE 
        WHEN fr.total_sales IS NULL THEN 'Sales Missing'
        ELSE 'Sales Present'
    END AS sales_status
FROM 
    final_report fr
WHERE 
    (fr.total_sales > 10000 OR fr.total_spent > 5000)
ORDER BY 
    fr.total_sales DESC NULLS LAST, fr.total_spent DESC;
