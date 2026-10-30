
WITH  nation_sales AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON l.l_partkey = p.p_partkey
    GROUP BY 
        n.n_nationkey, n.n_name, n.n_regionkey
),
top_nations AS (
    SELECT 
        ns.n_nationkey,
        ns.n_name,
        ns.total_sales
    FROM 
        nation_sales ns
    WHERE 
        ns.sales_rank <= 5
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS customer_rank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
final_report AS (
    SELECT 
        tn.n_name AS nation_name,
        co.c_name AS customer_name,
        co.total_spent,
        CASE 
            WHEN co.order_count > 0 THEN 'Active'
            ELSE 'Inactive'
        END AS customer_status
    FROM 
        top_nations tn
    FULL OUTER JOIN 
        customer_orders co ON tn.n_nationkey = co.c_custkey
)
SELECT 
    fr.nation_name,
    fr.customer_name,
    fr.total_spent,
    fr.customer_status
FROM 
    final_report fr
WHERE 
    fr.total_spent IS NOT NULL AND fr.customer_status = 'Active'
ORDER BY 
    fr.total_spent DESC;
