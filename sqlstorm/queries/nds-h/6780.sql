WITH TotalSales AS (
    SELECT 
        c.c_nationkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1993-01-01' AND DATE '1994-01-01'
    GROUP BY 
        c.c_nationkey
),
NationSales AS (
    SELECT 
        n.n_name,
        ts.total_revenue
    FROM 
        nation n
    JOIN 
        TotalSales ts ON n.n_nationkey = ts.c_nationkey
),
RankedSales AS (
    SELECT 
        ns.n_name,
        ns.total_revenue,
        RANK() OVER (ORDER BY ns.total_revenue DESC) AS sales_rank
    FROM 
        NationSales ns
)

SELECT 
    rs.n_name, 
    rs.total_revenue
FROM 
    RankedSales rs
WHERE 
    rs.sales_rank <= 10
ORDER BY 
    rs.sales_rank;
