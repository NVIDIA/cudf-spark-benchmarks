WITH regional_spending AS (
    SELECT 
        n.n_name AS nation_name,
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        supplier s ON l.l_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
        AND l.l_returnflag = 'N'
    GROUP BY 
        n.n_name, r.r_name
),
top_nations AS (
    SELECT 
        nation_name,
        region_name,
        total_revenue,
        total_orders,
        ROW_NUMBER() OVER (PARTITION BY region_name ORDER BY total_revenue DESC) AS rank
    FROM 
        regional_spending
)
SELECT 
    t.nation_name, 
    t.region_name, 
    t.total_revenue, 
    t.total_orders
FROM 
    top_nations t
WHERE 
    t.rank <= 5
ORDER BY 
    t.region_name, t.total_revenue DESC;