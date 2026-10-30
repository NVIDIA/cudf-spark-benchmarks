
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS Rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
), TotalSales AS (
    SELECT 
        o.o_orderkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS TotalSalesAmount
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    GROUP BY 
        o.o_orderkey
), SupplierSales AS (
    SELECT 
        rs.s_suppkey,
        COALESCE(SUM(ts.TotalSalesAmount), 0) AS SupplierSalesAmount
    FROM 
        RankedSuppliers rs
    LEFT JOIN 
        partsupp ps ON rs.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        lineitem li ON ps.ps_partkey = li.l_partkey
    LEFT JOIN 
        TotalSales ts ON li.l_orderkey = ts.o_orderkey
    GROUP BY 
        rs.s_suppkey
)
SELECT 
    n.n_name AS Nation,
    rs.s_name AS SupplierName,
    rs.TotalSupplyCost,
    ss.SupplierSalesAmount,
    (rs.TotalSupplyCost - ss.SupplierSalesAmount) AS CostDifference,
    CASE 
        WHEN ss.SupplierSalesAmount > 0 THEN 'Profitable'
        ELSE 'Non-Profitable'
    END AS ProfitabilityStatus
FROM 
    RankedSuppliers rs
JOIN 
    nation n ON rs.s_suppkey = n.n_nationkey
JOIN 
    SupplierSales ss ON rs.s_suppkey = ss.s_suppkey
WHERE 
    rs.Rank <= 3
ORDER BY 
    n.n_name, CostDifference DESC;
