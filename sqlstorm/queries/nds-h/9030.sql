WITH Revenue AS (
    SELECT 
        n.n_name AS nation,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND 
        o.o_orderdate < DATE '1996-01-01' + INTERVAL '1 year'
    GROUP BY 
        n.n_name
),
RnkRevenue AS (
    SELECT 
        nation,
        total_revenue,
        ROW_NUMBER() OVER (ORDER BY total_revenue DESC) AS rank
    FROM 
        Revenue
)
SELECT 
    r.nation,
    r.total_revenue
FROM 
    RnkRevenue r
WHERE 
    r.rank <= 5
ORDER BY 
    r.total_revenue DESC;