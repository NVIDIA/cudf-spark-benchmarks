WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= DATE '1996-01-01' AND l.l_shipdate < DATE '1997-01-01'
    GROUP BY 
        s.s_suppkey
),
NationSales AS (
    SELECT 
        n.n_nationkey,
        SUM(ss.TotalRevenue) AS NationRevenue
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        SupplierSales ss ON s.s_suppkey = ss.s_suppkey
    GROUP BY 
        n.n_nationkey
)
SELECT 
    r.r_name AS Region,
    SUM(ns.NationRevenue) AS TotalNationRevenue
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    NationSales ns ON n.n_nationkey = ns.n_nationkey
GROUP BY 
    r.r_name
ORDER BY 
    TotalNationRevenue DESC
LIMIT 10;