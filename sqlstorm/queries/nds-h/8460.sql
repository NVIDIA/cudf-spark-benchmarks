WITH OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT l.l_orderkey) AS lineitem_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
), CustomerSales AS (
    SELECT 
        c.c_custkey, 
        c.c_name,
        SUM(os.total_sales) AS customer_total_sales
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        OrderSummary os ON o.o_orderkey = os.o_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
), TopCustomers AS (
    SELECT 
        cs.c_custkey, 
        cs.c_name, 
        cs.customer_total_sales,
        ROW_NUMBER() OVER (ORDER BY cs.customer_total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
)
SELECT 
    tc.c_custkey,
    tc.c_name,
    tc.customer_total_sales,
    r.r_name AS region_name,
    n.n_name AS nation_name
FROM 
    TopCustomers tc
JOIN 
    customer c ON tc.c_custkey = c.c_custkey
JOIN 
    supplier s ON s.s_nationkey = c.c_nationkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.customer_total_sales DESC;
