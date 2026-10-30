WITH  SalesData AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank,
        o.o_orderdate
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
RankedSales AS (
    SELECT 
        sd.o_orderkey,
        sd.total_sales,
        sd.o_orderdate,
        CASE 
            WHEN sd.sales_rank <= 10 THEN 'Top 10'
            ELSE 'Other'
        END AS sales_category
    FROM 
        SalesData sd
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    ps.ps_availqty AS available_quantity,
    SUM(rs.total_sales) AS region_sales
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
    RankedSales rs ON p.p_partkey = rs.o_orderkey
GROUP BY 
    r.r_name, n.n_name, s.s_name, p.p_name, ps.ps_availqty
HAVING 
    SUM(rs.total_sales) IS NOT NULL
ORDER BY 
    region_sales DESC
LIMIT 10;
