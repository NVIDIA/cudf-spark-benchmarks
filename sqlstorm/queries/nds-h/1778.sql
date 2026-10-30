WITH SupplierSales AS (
    SELECT 
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalSales
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE 
        l.l_shipdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
    GROUP BY 
        s.s_name
),  
RankedSales AS (
    SELECT 
        s_name,
        TotalSales,
        RANK() OVER (ORDER BY TotalSales DESC) AS SalesRank
    FROM 
        SupplierSales
)
SELECT 
    r.r_name AS RegionName,
    COALESCE(rs.s_name, 'Unknown') AS SupplierName,
    COALESCE(rs.TotalSales, 0.00) AS TotalSales,
    CASE 
        WHEN rs.TotalSales IS NULL THEN 'No Sales Recorded'
        ELSE 'Sales Recorded'
    END AS SalesStatus
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    RankedSales rs ON c.c_name = rs.s_name
WHERE 
    r.r_name LIKE 'Asia%' OR r.r_name IS NULL
ORDER BY 
    r.r_name, rs.TotalSales DESC;