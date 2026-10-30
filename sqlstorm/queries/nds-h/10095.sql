WITH TotalRevenue AS (
    SELECT 
        l_orderkey,
        SUM(l_extendedprice * (1 - l_discount)) AS revenue
    FROM 
        lineitem
    WHERE 
        l_shipdate >= DATE '1996-01-01' AND 
        l_shipdate < DATE '1996-12-31'
    GROUP BY 
        l_orderkey
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice,
    COALESCE(tr.revenue, 0) AS total_revenue
FROM
    orders o
LEFT JOIN
    TotalRevenue tr ON o.o_orderkey = tr.l_orderkey
WHERE 
    o.o_orderstatus = 'O'
ORDER BY 
    o.o_orderdate;
