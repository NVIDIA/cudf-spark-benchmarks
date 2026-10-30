WITH TotalSales AS (
    SELECT 
        l_partkey,
        SUM(l_extendedprice * (1 - l_discount)) AS revenue
    FROM 
        lineitem
    WHERE 
        l_shipdate >= DATE '1994-01-01' AND l_shipdate < DATE '1995-01-01'
    GROUP BY 
        l_partkey
),
RankedSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ts.revenue,
        RANK() OVER (ORDER BY ts.revenue DESC) AS rank
    FROM 
        part p
    JOIN 
        TotalSales ts ON p.p_partkey = ts.l_partkey
)
SELECT 
    rs.rank,
    rs.p_name,
    rs.revenue
FROM 
    RankedSales rs
WHERE 
    rs.rank <= 20
ORDER BY 
    rs.rank;
