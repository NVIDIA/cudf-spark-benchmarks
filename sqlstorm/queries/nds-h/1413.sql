WITH SupplierRevenue AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
), CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), RegionSales AS (
    SELECT 
        r.r_regionkey, 
        r.r_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS region_sales
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        r.r_regionkey, r.r_name
), SalesRank AS (
    SELECT 
        r.r_name, 
        r.region_sales,
        RANK() OVER (ORDER BY r.region_sales DESC) AS sales_rank
    FROM 
        RegionSales r
)
SELECT 
    sr.r_name AS region, 
    COALESCE(cr.order_count, 0) AS order_count,
    COALESCE(cr.total_spent, 0) AS total_spent,
    sr.sales_rank
FROM 
    SalesRank sr
LEFT JOIN 
    CustomerOrders cr ON sr.r_name = cr.c_name
WHERE 
    sr.sales_rank <= 5
ORDER BY 
    sr.sales_rank;
