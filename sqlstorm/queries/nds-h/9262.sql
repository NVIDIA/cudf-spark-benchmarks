WITH RankedSales AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank,
        n.n_name AS nation_name,
        r.r_name AS region_name
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        supplier s ON l.l_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND 
        o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        c.c_custkey, c.c_name, n.n_regionkey, n.n_name, r.r_name
),
TopCustomers AS (
    SELECT 
        sales_rank,
        c_custkey,
        c_name,
        total_sales,
        nation_name,
        region_name
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 10
)
SELECT 
    rc.cust_rank,
    tc.c_name,
    tc.total_sales,
    tc.nation_name,
    tc.region_name
FROM 
    (SELECT ROW_NUMBER() OVER (ORDER BY SUM(total_sales) DESC) AS cust_rank, c_custkey
     FROM TopCustomers
     GROUP BY c_custkey) rc
JOIN 
    TopCustomers tc ON rc.c_custkey = tc.c_custkey
ORDER BY 
    total_sales DESC;