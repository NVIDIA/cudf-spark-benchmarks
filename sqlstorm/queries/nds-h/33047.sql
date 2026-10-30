
WITH  RegionalSales AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY r.r_regionkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        r.r_regionkey, r.r_name
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopSalesOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'F'
),
FilteredSales AS (
    SELECT 
        rs.r_regionkey,
        rs.r_name,
        SUM(rs.total_sales) AS region_sales,
        COUNT(DISTINCT co.c_custkey) AS distinct_customers
    FROM 
        RegionalSales rs
    INNER JOIN 
        CustomerOrderSummary co ON rs.r_regionkey = co.c_custkey
    GROUP BY 
        rs.r_regionkey, rs.r_name
)
SELECT 
    f.r_name,
    f.region_sales,
    f.distinct_customers,
    ts.o_orderkey,
    ts.o_orderdate,
    ts.o_totalprice
FROM 
    FilteredSales f
LEFT JOIN 
    TopSalesOrders ts ON f.region_sales > (SELECT AVG(region_sales) FROM FilteredSales)
ORDER BY 
    f.region_sales DESC, ts.o_totalprice DESC
LIMIT 10;
