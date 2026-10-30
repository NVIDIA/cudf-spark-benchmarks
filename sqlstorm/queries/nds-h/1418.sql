
WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_availqty) AS TotalAvailableQty,
        AVG(ps.ps_supplycost) AS AverageSupplyCost,
        r.r_name AS RegionName
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        s.s_suppkey, s.s_name, r.r_name
), OrderDetails AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
        COUNT(DISTINCT l.l_linenumber) AS LineCount
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O' 
        AND l.l_shipdate > '1996-01-01' 
        AND l.l_returnflag = 'N'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
), PriceBenchmark AS (
    SELECT 
        d.RegionName,
        COUNT(DISTINCT o.o_orderkey) AS OrderCount,
        SUM(o.TotalRevenue) AS TotalSales,
        AVG(o.TotalRevenue) AS AverageOrderValue
    FROM 
        SupplierDetails d
    LEFT JOIN 
        OrderDetails o ON d.s_suppkey = (SELECT ps.ps_suppkey 
                                          FROM partsupp ps 
                                          WHERE ps.ps_partkey IN (SELECT p.p_partkey 
                                                                  FROM part p 
                                                                  WHERE p.p_container = 'SMALL')
                                          LIMIT 1) 
    GROUP BY 
        d.RegionName
)
SELECT 
    RegionName, 
    OrderCount, 
    TotalSales, 
    AverageOrderValue,
    CASE 
        WHEN AverageOrderValue IS NULL THEN 'No Sales'
        WHEN AverageOrderValue < 10000 THEN 'Low Sales'
        ELSE 'High Sales' 
    END AS SalesCategory
FROM 
    PriceBenchmark
ORDER BY 
    TotalSales DESC;
