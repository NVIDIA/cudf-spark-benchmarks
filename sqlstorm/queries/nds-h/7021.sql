WITH HistoricalData AS (
    SELECT 
        c.c_name AS customer_name,
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        supplier s ON l.l_suppkey = s.s_suppkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey AND s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1994-01-01' AND DATE '1995-01-01'
    GROUP BY 
        customer_name, nation_name
),
RevenueRanked AS (
    SELECT 
        customer_name, 
        nation_name, 
        total_revenue, 
        total_orders,
        RANK() OVER (PARTITION BY nation_name ORDER BY total_revenue DESC) AS revenue_rank
    FROM 
        HistoricalData
)
SELECT 
    customer_name,
    nation_name,
    total_revenue,
    total_orders
FROM 
    RevenueRanked
WHERE 
    revenue_rank <= 10
ORDER BY 
    nation_name, total_revenue DESC;
