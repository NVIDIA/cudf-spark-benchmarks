WITH RegionalSales AS (
    SELECT 
        R.r_name AS region,
        SUM(L.l_extendedprice * (1 - L.l_discount)) AS total_sales
    FROM 
        region R
    JOIN 
        nation N ON R.r_regionkey = N.n_regionkey
    JOIN 
        supplier S ON N.n_nationkey = S.s_nationkey
    JOIN 
        partsupp PS ON S.s_suppkey = PS.ps_suppkey
    JOIN 
        part P ON PS.ps_partkey = P.p_partkey
    JOIN 
        lineitem L ON P.p_partkey = L.l_partkey
    JOIN 
        orders O ON L.l_orderkey = O.o_orderkey
    WHERE 
        O.o_orderdate >= DATE '1997-01-01' AND O.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        R.r_name
), RankedSales AS (
    SELECT 
        region, 
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS rank
    FROM 
        RegionalSales
)
SELECT 
    region,
    total_sales
FROM 
    RankedSales
WHERE 
    rank <= 5
ORDER BY 
    total_sales DESC;