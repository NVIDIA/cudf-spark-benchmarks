WITH TotalSales AS (
    SELECT 
        l_partkey,
        SUM(l_extendedprice * (1 - l_discount)) AS sales
    FROM 
        lineitem
    WHERE 
        l_shipdate >= DATE '1997-01-01' AND l_shipdate < DATE '1998-01-01'
    GROUP BY 
        l_partkey
),
RankedSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        ts.sales,
        RANK() OVER (ORDER BY ts.sales DESC) AS rank
    FROM 
        part p
    JOIN 
        TotalSales ts ON p.p_partkey = ts.l_partkey
)
SELECT 
    rs.rank,
    rs.p_partkey,
    rs.p_name,
    rs.p_brand,
    rs.p_type,
    rs.p_size,
    rs.sales
FROM 
    RankedSales rs
WHERE 
    rs.rank <= 10;