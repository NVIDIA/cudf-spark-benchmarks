
WITH CTE_SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_sales
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem li ON ps.ps_partkey = li.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CTE_CustomerStats AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
TotalRegions AS (
    SELECT 
        r.r_regionkey,
        COUNT(DISTINCT n.n_nationkey) AS num_nations
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY 
        r.r_regionkey
)
SELECT 
    r.r_name,
    COALESCE(cte_sales.total_sales, 0) AS total_supplier_sales,
    COALESCE(cust_stats.total_orders, 0) AS total_customer_orders,
    tr.num_nations,
    CASE 
        WHEN COALESCE(cte_sales.total_sales, 0) > 100000 THEN 'High Value'
        ELSE 'Low Value'
    END AS supplier_value
FROM 
    region r
LEFT JOIN 
    TotalRegions tr ON r.r_regionkey = tr.r_regionkey
LEFT JOIN 
    CTE_SupplierSales cte_sales ON cte_sales.s_suppkey = (
        SELECT ps.ps_suppkey
        FROM partsupp ps
        WHERE ps.ps_partkey IN (
            SELECT p.p_partkey 
            FROM part p
            WHERE p.p_type LIKE '%metal%'
            EXCEPT
            SELECT l.l_partkey
            FROM lineitem l
            WHERE l.l_returnflag = 'R'
        )
        LIMIT 1
    )
LEFT JOIN 
    CTE_CustomerStats cust_stats ON cust_stats.total_spent > 5000 AND cust_stats.total_orders > 5
ORDER BY 
    r.r_name, supplier_value DESC;
