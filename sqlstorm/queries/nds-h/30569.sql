WITH  RegionalSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY r.r_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
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
        r.r_name
),
TopRegions AS (
    SELECT 
        region_name, 
        total_sales
    FROM 
        RegionalSales
    WHERE 
        sales_rank <= 5
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_order_value,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name
    FROM 
        CustomerOrders c
    WHERE 
        total_order_value = (SELECT MAX(total_order_value) FROM CustomerOrders)
)
SELECT 
    r.region_name,
    r.total_sales,
    c.c_name,
    COALESCE(o.total_order_value, 0) AS customer_order_value
FROM 
    TopRegions r
LEFT JOIN 
    TopCustomers c ON 1=1  
LEFT JOIN 
    CustomerOrders o ON c.c_custkey = o.c_custkey
ORDER BY 
    r.total_sales DESC, c.c_name;