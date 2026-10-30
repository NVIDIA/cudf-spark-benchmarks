WITH  RegionSales AS (
    SELECT 
        r.r_regionkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
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
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        r.r_regionkey
    
    UNION ALL
    
    SELECT 
        r.r_regionkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= DATE '1996-01-01' 
        AND l.l_shipdate < DATE '1996-12-31'
    GROUP BY 
        r.r_regionkey
),
CustomerAggregate AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
SalesRanked AS (
    SELECT 
        r.r_name,
        COALESCE(rs.total_sales, 0) AS region_sales,
        DENSE_RANK() OVER (ORDER BY COALESCE(rs.total_sales, 0) DESC) AS sales_rank
    FROM 
        region r
    LEFT JOIN 
        RegionSales rs ON r.r_regionkey = rs.r_regionkey
)

SELECT 
    cr.c_custkey,
    cr.total_spent,
    cr.total_orders,
    cr.avg_order_value,
    sr.r_name,
    sr.region_sales,
    sr.sales_rank
FROM 
    CustomerAggregate cr
JOIN 
    SalesRanked sr ON cr.total_orders > 0
WHERE 
    cr.total_spent IS NOT NULL 
    AND sr.sales_rank <= 5
ORDER BY 
    sr.sales_rank, cr.total_spent DESC;