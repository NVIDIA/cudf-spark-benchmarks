WITH RegionalSales AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
        AND l.l_returnflag = 'N'
    GROUP BY 
        n.n_name
),
TopRegions AS (
    SELECT 
        nation_name, 
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS SalesRank
    FROM 
        RegionalSales
    )
SELECT 
    TR.nation_name,
    TR.total_sales,
    R.r_comment
FROM 
    TopRegions TR
JOIN 
    nation N ON TR.nation_name = N.n_name
JOIN 
    region R ON N.n_regionkey = R.r_regionkey
WHERE 
    TR.SalesRank <= 5
ORDER BY 
    TR.total_sales DESC;