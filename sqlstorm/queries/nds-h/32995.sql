WITH  SalesCTE AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS TotalSales,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(o.o_totalprice) DESC) AS SalesRank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= '1997-01-01' OR o.o_orderdate IS NULL
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 0
    
    UNION ALL
    
    SELECT 
        s.s_suppkey AS c_custkey,
        s.s_name AS c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalSales,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS SalesRank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 0
)

SELECT 
    RANK() OVER (ORDER BY TotalSales DESC) AS OverallSalesRank,
    c.*, 
    r.r_name,
    n.n_name
FROM 
    SalesCTE c
LEFT JOIN 
    nation n ON c.c_custkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    c.TotalSales IS NOT NULL
ORDER BY 
    OverallSalesRank;