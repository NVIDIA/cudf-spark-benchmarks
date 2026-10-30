
WITH SupplierSales AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31' 
        AND l.l_returnflag = 'N'
    GROUP BY 
        s.s_suppkey, s.s_name
), RankedSales AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        s.total_sales,
        s.order_count,
        RANK() OVER (ORDER BY s.total_sales DESC) AS sales_rank
    FROM 
        SupplierSales s
), CustomerStats AS (
    SELECT 
        c.c_custkey, 
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    r.s_suppkey, 
    r.s_name, 
    r.total_sales, 
    r.order_count,
    COALESCE(c.total_spent, 0) AS total_spent_by_customer,
    c.order_count AS customer_order_count,
    CASE 
        WHEN r.sales_rank <= 10 THEN 'Top Supplier'
        ELSE 'Regular Supplier'
    END AS supplier_rating
FROM 
    RankedSales r
LEFT JOIN 
    CustomerStats c ON r.s_suppkey = c.c_custkey
WHERE 
    r.total_sales > (SELECT AVG(total_sales) FROM SupplierSales) 
ORDER BY 
    r.total_sales DESC;
