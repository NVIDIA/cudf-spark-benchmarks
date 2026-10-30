WITH TotalSales AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS sales
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '1996-01-01' AND l.l_shipdate < DATE '1996-12-31'
    GROUP BY 
        l.l_orderkey
),

TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        SUM(ts.sales) AS total_sales
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        TotalSales ts ON o.o_orderkey = ts.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_acctbal
    ORDER BY 
        total_sales DESC
    LIMIT 10
)

SELECT 
    tc.c_name,
    tc.total_sales,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(o.o_totalprice) AS avg_order_price,
    SUM(s.s_acctbal) AS supplier_accounts
FROM 
    TopCustomers tc
JOIN 
    orders o ON tc.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
GROUP BY 
    tc.c_name, tc.total_sales
HAVING 
    SUM(s.s_acctbal) > 10000
ORDER BY 
    tc.total_sales DESC;