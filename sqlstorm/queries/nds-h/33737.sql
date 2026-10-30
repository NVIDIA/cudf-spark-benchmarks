WITH  regional_sales AS (
    SELECT 
        n.n_name AS nation,
        r.r_name AS region,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY SUM(li.l_extendedprice * (1 - li.l_discount)) DESC) AS sales_rank
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem li ON p.p_partkey = li.l_partkey
    GROUP BY 
        n.n_name, r.r_name
),
filtered_sales AS (
    SELECT 
        nation,
        region,
        total_sales
    FROM 
        regional_sales
    WHERE 
        sales_rank <= 5
),
high_value_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    r.region,
    r.nation,
    r.total_sales,
    COALESCE(h.c_name, 'No Orders') AS high_value_customer,
    COALESCE(h.total_order_value, 0) AS customer_order_value
FROM 
    filtered_sales r
LEFT JOIN 
    high_value_orders h ON r.nation = h.c_name
ORDER BY 
    r.region, r.total_sales DESC;

