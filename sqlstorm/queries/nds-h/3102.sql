WITH RegionalSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
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
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1998-01-01'
        AND l.l_returnflag = 'N'
    GROUP BY 
        r.r_name
),
TopRegions AS (
    SELECT 
        region_name, 
        total_sales
    FROM 
        RegionalSales
    WHERE 
        sales_rank <= 5
)
SELECT 
    t.region_name,
    t.total_sales,
    COALESCE(t.total_sales / (SELECT SUM(total_sales) FROM TopRegions), 0) AS sales_percentage,
    p.p_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(o.o_totalprice) AS average_order_value
FROM 
    TopRegions t
LEFT JOIN 
    lineitem l ON t.total_sales = l.l_extendedprice * (1 - l.l_discount)
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    part p ON l.l_partkey = p.p_partkey
GROUP BY 
    t.region_name, t.total_sales, p.p_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 0
ORDER BY 
    t.total_sales DESC, average_order_value ASC;