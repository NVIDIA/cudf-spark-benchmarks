
WITH  OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
),
CustomerSales AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(os.total_sales) AS total_sales
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        OrderSummary os ON o.o_orderkey = os.o_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > (SELECT AVG(total_sales) FROM CustomerSales)
),
SalesRanking AS (
    SELECT 
        cs.c_name AS customer_name,
        cs.total_sales,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
)
SELECT 
    sr.customer_name,
    sr.total_sales,
    COALESCE(ss.total_sales, 0) AS supplier_sales,
    CASE 
        WHEN sr.total_sales > COALESCE(ss.total_sales, 0) THEN 'Customer Dominant'
        ELSE 'Supplier Dominant'
    END AS dominance_type
FROM 
    SalesRanking sr
LEFT JOIN 
    SupplierSales ss ON sr.customer_name LIKE CONCAT('%', ss.s_name, '%')
WHERE 
    sr.sales_rank <= 10
ORDER BY 
    sr.total_sales DESC;
