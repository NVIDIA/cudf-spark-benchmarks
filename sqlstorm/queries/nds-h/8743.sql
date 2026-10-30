WITH TotalRevenue AS (
    SELECT 
        SUM(l_extendedprice * (1 - l_discount)) AS revenue,
        n_name AS nation,
        o_orderdate
    FROM 
        lineitem
    JOIN 
        orders ON l_orderkey = o_orderkey
    JOIN 
        supplier ON l_suppkey = s_suppkey
    JOIN 
        partsupp ON l_partkey = ps_partkey AND s_suppkey = ps_suppkey
    JOIN 
        nation ON s_nationkey = n_nationkey
    WHERE 
        o_orderdate >= DATE '1997-01-01' AND 
        o_orderdate < DATE '1998-01-01' AND 
        l_returnflag = 'N'
    GROUP BY 
        n_name, o_orderdate
),
RankedRevenue AS (
    SELECT 
        nation,
        revenue,
        ROW_NUMBER() OVER (PARTITION BY nation ORDER BY revenue DESC) AS revenue_rank
    FROM 
        TotalRevenue
)
SELECT 
    nation, 
    revenue 
FROM 
    RankedRevenue 
WHERE 
    revenue_rank <= 5 
ORDER BY 
    nation, 
    revenue DESC;