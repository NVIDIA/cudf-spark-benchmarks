WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_size,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_size ORDER BY p.p_retailprice DESC) AS Rank
    FROM 
        part p
    WHERE 
        p.p_name LIKE '%Steel%'
), 
AggregatedData AS (
    SELECT 
        s.s_name,
        COUNT(DISTINCT o.o_orderkey) AS TotalOrders,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalSales,
        SUM(l.l_quantity) AS TotalQuantity
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        RankedParts rp ON ps.ps_partkey = rp.p_partkey
    JOIN 
        lineitem l ON rp.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        s.s_name
)
SELECT 
    a.s_name,
    a.TotalOrders,
    a.TotalSales,
    a.TotalQuantity,
    CASE 
        WHEN a.TotalSales > 10000 THEN 'High Performer' 
        WHEN a.TotalSales BETWEEN 5000 AND 10000 THEN 'Medium Performer' 
        ELSE 'Low Performer' 
    END AS PerformanceRating
FROM 
    AggregatedData a
WHERE 
    a.TotalOrders > 5
ORDER BY 
    a.TotalSales DESC;
