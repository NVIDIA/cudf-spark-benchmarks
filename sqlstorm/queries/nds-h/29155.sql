WITH AggregatedSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey, p.p_name, s.s_name
),
RankedSales AS (
    SELECT 
        p_partkey,
        p_name,
        s_name,
        total_sales,
        RANK() OVER (PARTITION BY p_partkey ORDER BY total_sales DESC) AS sales_rank
    FROM 
        AggregatedSales
)
SELECT 
    r.p_partkey,
    r.p_name,
    r.s_name,
    r.total_sales,
    SUM(r.total_sales) OVER () AS grand_total_sales,
    r.sales_rank
FROM 
    RankedSales r
WHERE 
    r.sales_rank <= 3
ORDER BY 
    r.p_partkey, r.sales_rank;
