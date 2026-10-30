WITH RegionSales AS (
    SELECT 
        r.r_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
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
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
        AND l.l_returnflag = 'N'
    GROUP BY 
        r.r_name
), RankedSales AS (
    SELECT 
        r_name,
        total_sales,
        order_count,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        RegionSales
), CustomerSpend AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS customer_spend
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        c.c_custkey, c.c_name
), TopCustomers AS (
    SELECT 
        c.c_name,
        cs.customer_spend,
        RANK() OVER (ORDER BY cs.customer_spend DESC) AS customer_rank
    FROM 
        CustomerSpend cs
    JOIN 
        customer c ON cs.c_custkey = c.c_custkey
    WHERE 
        cs.customer_spend > 10000
)

SELECT 
    r.r_name,
    r.total_sales,
    r.order_count,
    tc.c_name AS top_customer,
    tc.customer_spend
FROM 
    RankedSales r
LEFT JOIN 
    TopCustomers tc ON r.sales_rank = tc.customer_rank
WHERE 
    r.total_sales > 50000
ORDER BY 
    r.total_sales DESC, tc.customer_spend DESC;