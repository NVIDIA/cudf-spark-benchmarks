WITH OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name AS customer_name,
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' 
        AND o.o_orderdate < DATE '1996-01-01'
        AND l.l_shipdate >= DATE '1995-01-01'
        AND l.l_shipdate < DATE '1996-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_name, n.n_name
),
TopNations AS (
    SELECT 
        nation_name,
        SUM(total_revenue) AS revenue
    FROM 
        OrderSummary
    GROUP BY 
        nation_name
    ORDER BY 
        revenue DESC
    LIMIT 5
)
SELECT 
    os.o_orderkey,
    os.o_orderdate,
    os.total_revenue,
    tn.nation_name
FROM 
    OrderSummary os
JOIN 
    TopNations tn ON os.nation_name = tn.nation_name
ORDER BY 
    os.total_revenue DESC, os.o_orderdate ASC;
