WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        RANK() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderstatus = 'F' 
        AND l.l_shipdate >= DATE '1997-01-01' 
        AND l.l_shipdate < DATE '1997-12-31'
    GROUP BY 
        s.s_suppkey, s.s_name
),

TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COALESCE(ss.total_sales, 0) AS total_sales,
        ss.order_count,
        ss.sales_rank
    FROM 
        supplier s
    LEFT JOIN 
        SupplierSales ss ON s.s_suppkey = ss.s_suppkey
    WHERE 
        s.s_acctbal > 1000
),

TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        ROW_NUMBER() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS customer_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 5000
)

SELECT 
    ts.s_suppkey,
    ts.s_name AS supplier_name,
    ts.s_acctbal,
    ts.total_sales,
    tc.c_custkey AS top_customer_id,
    tc.c_name AS top_customer_name,
    tc.total_spent,
    CASE 
        WHEN ts.sales_rank IS NULL THEN 'No Sales'
        WHEN ts.sales_rank > 5 THEN 'Low Rank Supplier'
        ELSE 'Top Performer'
    END AS supplier_status,
    CASE 
        WHEN tc.customer_rank <= 3 THEN 'Premium Customer'
        ELSE 'Regular Customer'
    END AS customer_status
FROM 
    TopSuppliers ts
FULL OUTER JOIN 
    TopCustomers tc ON ts.s_suppkey = tc.c_custkey
WHERE 
    (ts.total_sales > 0 OR tc.total_spent > 0)
ORDER BY 
    ts.total_sales DESC, tc.total_spent DESC;