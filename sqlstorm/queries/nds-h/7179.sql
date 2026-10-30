WITH nation_summary AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(s.s_acctbal) AS total_balance,
        COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY 
        n.n_name
),
order_summary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
ranked_orders AS (
    SELECT 
        os.o_orderkey,
        os.o_orderdate,
        os.total_revenue,
        RANK() OVER (ORDER BY os.total_revenue DESC) AS revenue_rank
    FROM 
        order_summary os
)
SELECT 
    ns.nation_name,
    ns.total_balance,
    ns.customer_count,
    ro.total_revenue,
    ro.o_orderdate
FROM 
    nation_summary ns
JOIN 
    ranked_orders ro ON ns.customer_count > 100
WHERE 
    ro.revenue_rank <= 10
ORDER BY 
    ns.total_balance DESC, 
    ro.total_revenue DESC;