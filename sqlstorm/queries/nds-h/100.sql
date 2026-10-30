WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(*) AS total_orders
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
RankedSales AS (
    SELECT 
        s.s_name,
        s.total_sales,
        s.total_orders,
        RANK() OVER (ORDER BY s.total_sales DESC) AS sales_rank
    FROM 
        SupplierSales s
),
FilteredCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        co.order_count
    FROM 
        customer c
    JOIN 
        CustomerOrders co ON c.c_custkey = co.c_custkey
    WHERE 
        co.order_count > 10
)
SELECT 
    rs.s_name,
    rs.total_sales,
    fc.c_name,
    fc.order_count
FROM 
    RankedSales rs
FULL OUTER JOIN 
    FilteredCustomers fc ON rs.total_orders = fc.order_count 
WHERE 
    rs.total_sales IS NOT NULL OR fc.order_count IS NOT NULL
ORDER BY 
    rs.sales_rank ASC, fc.order_count DESC;
