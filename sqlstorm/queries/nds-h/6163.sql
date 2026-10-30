WITH SalesData AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        n.n_name AS nation_name,
        sum(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
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
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        c.c_custkey, c.c_name, n.n_name
), RankedSales AS (
    SELECT 
        sd.c_custkey,
        sd.c_name,
        sd.nation_name,
        sd.total_sales,
        RANK() OVER (PARTITION BY sd.nation_name ORDER BY sd.total_sales DESC) AS sales_rank
    FROM 
        SalesData sd
)
SELECT 
    r.nation_name,
    COUNT(rs.c_custkey) AS num_top_customers,
    SUM(rs.total_sales) AS total_sales_sum,
    AVG(rs.total_sales) AS avg_sales_per_top_customer
FROM 
    RankedSales rs
JOIN 
    (SELECT DISTINCT nation_name FROM RankedSales WHERE sales_rank <= 5) r ON rs.nation_name = r.nation_name
GROUP BY 
    r.nation_name
ORDER BY 
    total_sales_sum DESC;