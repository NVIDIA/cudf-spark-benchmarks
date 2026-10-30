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
        o.o_orderstatus = 'O'
        AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        s.s_suppkey, s.s_name
), RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.total_sales,
        s.order_count,
        RANK() OVER (ORDER BY s.total_sales DESC) AS sales_rank
    FROM 
        SupplierSales s
), ActiveCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        c.c_mktsegment
    FROM 
        customer c 
    WHERE 
        c.c_acctbal > 500
), TopSalesSuppliers AS (
    SELECT 
        r.s_suppkey,
        r.s_name,
        r.total_sales,
        r.order_count
    FROM 
        RankedSuppliers r
    WHERE 
        r.sales_rank <= 10
)
SELECT 
    t.s_suppkey,
    t.s_name,
    COALESCE(a.c_name, 'No Active Customer') AS active_customer_name,
    t.total_sales,
    t.order_count,
    (SELECT COUNT(*) FROM ActiveCustomers c WHERE c.c_acctbal > t.total_sales) AS active_customer_compared_count
FROM 
    TopSalesSuppliers t
LEFT JOIN 
    ActiveCustomers a ON t.s_suppkey = a.c_custkey
ORDER BY 
    t.total_sales DESC;