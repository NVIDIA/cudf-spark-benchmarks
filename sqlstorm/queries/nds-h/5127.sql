WITH RegionalPerformance AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        SUM(o.o_totalprice) AS total_sales,
        COUNT(DISTINCT c.c_custkey) AS unique_customers,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        AVG(o.o_totalprice) AS avg_order_value
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
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
    GROUP BY 
        r.r_name, n.n_name
),
SalesRanking AS (
    SELECT 
        region_name,
        nation_name,
        total_sales,
        unique_customers,
        total_orders,
        avg_order_value,
        RANK() OVER (PARTITION BY region_name ORDER BY total_sales DESC) AS sales_rank
    FROM 
        RegionalPerformance
)
SELECT 
    r.region_name,
    r.nation_name,
    r.total_sales,
    r.unique_customers,
    r.total_orders,
    r.avg_order_value,
    r.sales_rank
FROM 
    SalesRanking r
WHERE 
    r.sales_rank <= 5
ORDER BY 
    r.region_name, 
    r.sales_rank;