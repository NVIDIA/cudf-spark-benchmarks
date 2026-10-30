WITH RegionalSales AS (
    SELECT 
        r.r_name AS Region,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalSales
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
        o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
    GROUP BY
        r.r_name
),
RankedSales AS (
    SELECT 
        Region,
        TotalSales,
        RANK() OVER (ORDER BY TotalSales DESC) AS SalesRank
    FROM 
        RegionalSales
)
SELECT 
    R.Region,
    R.TotalSales,
    R.SalesRank
FROM 
    RankedSales R
WHERE 
    R.SalesRank <= 5
ORDER BY 
    R.TotalSales DESC;