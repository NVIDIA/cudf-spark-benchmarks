WITH RegionalData AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        COUNT(DISTINCT c.c_custkey) AS total_customers
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
        l.l_shipdate >= DATE '1996-01-01' AND l.l_shipdate < DATE '1997-01-01'
    GROUP BY 
        r.r_name, n.n_name
),
RankedData AS (
    SELECT 
        region_name,
        nation_name,
        total_sales,
        total_orders,
        total_customers,
        RANK() OVER (PARTITION BY region_name ORDER BY total_sales DESC) AS sales_rank
    FROM 
        RegionalData
)
SELECT 
    region_name,
    nation_name,
    total_sales,
    total_orders,
    total_customers
FROM 
    RankedData
WHERE 
    sales_rank <= 5
ORDER BY 
    region_name, total_sales DESC;