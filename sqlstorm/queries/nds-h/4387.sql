
WITH RegionalSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
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
    WHERE 
        l.l_shipdate >= DATE '1997-01-01' 
        AND l.l_shipdate < DATE '1998-01-01'
        AND l.l_returnflag = 'N'
    GROUP BY 
        r.r_name
),
CustomerOrders AS (
    SELECT 
        c.c_name AS customer_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_name
),
RankedSales AS (
    SELECT 
        region_name,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        RegionalSales
)
SELECT 
    r.region_name,
    r.total_sales,
    COALESCE(c.total_orders, 0) AS total_orders,
    COALESCE(c.total_order_value, 0.00) AS total_order_value,
    r.sales_rank
FROM 
    RankedSales r
LEFT JOIN 
    CustomerOrders c ON r.region_name = c.customer_name
WHERE 
    r.sales_rank <= 5
ORDER BY 
    r.total_sales DESC;
