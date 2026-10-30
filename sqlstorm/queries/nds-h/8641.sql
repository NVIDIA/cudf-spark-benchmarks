
WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
top_nation_revenue AS (
    SELECT 
        n.n_name,
        SUM(ri.revenue) AS total_revenue
    FROM 
        ranked_orders ri
    JOIN 
        customer c ON ri.o_orderkey = c.c_custkey
    JOIN 
        supplier s ON c.c_nationkey = s.s_nationkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        n.n_name
    ORDER BY 
        total_revenue DESC
),
final_result AS (
    SELECT 
        n.n_name,
        tn.total_revenue,
        RANK() OVER (ORDER BY tn.total_revenue DESC) AS rank
    FROM 
        top_nation_revenue tn
    JOIN 
        nation n ON tn.n_name = n.n_name
)
SELECT 
    fr.rank,
    fr.n_name,
    fr.total_revenue
FROM 
    final_result fr
WHERE 
    fr.rank <= 10;
