WITH RegionalSales AS (
    SELECT 
        r.r_name AS Region,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalSales
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        r.r_name
),
TopRegions AS (
    SELECT 
        Region,
        TotalSales,
        RANK() OVER (ORDER BY TotalSales DESC) AS SalesRank
    FROM 
        RegionalSales
)

SELECT 
    tr.Region,
    tr.TotalSales,
    COUNT(DISTINCT s.s_suppkey) AS SupplierCount,
    AVG(s.s_acctbal) AS AvgSupplierAcctBal
FROM 
    TopRegions tr
JOIN 
    partsupp ps ON ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_container = 'SM CASE')
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    tr.SalesRank <= 5
GROUP BY 
    tr.Region, tr.TotalSales
ORDER BY 
    tr.TotalSales DESC;