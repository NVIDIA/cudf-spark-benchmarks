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
        o.o_orderdate >= '1997-01-01' 
        AND o.o_orderdate < '1997-12-31'
    GROUP BY 
        r.r_name
), CustomerSales AS (
    SELECT 
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS customer_sales
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        c.c_custkey
), RankedSales AS (
    SELECT 
        r.r_name,
        rs.total_sales,
        ROW_NUMBER() OVER (ORDER BY rs.total_sales DESC) AS sales_rank
    FROM 
        RegionSales rs
    LEFT JOIN 
        region r ON rs.r_name = r.r_name
)
SELECT 
    r.r_name,
    COALESCE(rs.total_sales, 0) AS total_sales,
    cs.customer_sales,
    (CASE 
        WHEN cs.customer_sales IS NULL THEN 'No Orders'
        ELSE 'Has Orders'
     END) AS order_status
FROM 
    region r
LEFT JOIN 
    RankedSales rs ON r.r_name = rs.r_name
LEFT JOIN 
    CustomerSales cs ON cs.customer_sales > 1000
WHERE 
    r.r_name IS NOT NULL
ORDER BY 
    r.r_name;