
WITH supplier_totals AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
order_details AS (
    SELECT 
        o.o_orderkey,
        c.c_nationkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    GROUP BY 
        o.o_orderkey, c.c_nationkey
),
nation_revenue AS (
    SELECT 
        n.n_nationkey,
        SUM(od.total_revenue) AS total_nation_revenue
    FROM 
        nation n
    LEFT JOIN 
        order_details od ON n.n_nationkey = od.c_nationkey
    GROUP BY 
        n.n_nationkey
),
ranked_suppliers AS (
    SELECT 
        st.s_suppkey,
        st.s_name,
        st.total_cost,
        RANK() OVER (ORDER BY st.total_cost DESC) AS cost_rank
    FROM 
        supplier_totals st
)
SELECT 
    nr.n_nationkey,
    COALESCE(nr.total_nation_revenue, 0) AS total_nation_revenue,
    rs.s_name,
    rs.total_cost
FROM 
    nation_revenue nr
FULL OUTER JOIN 
    ranked_suppliers rs ON rs.cost_rank <= 5
WHERE 
    (nr.total_nation_revenue IS NOT NULL OR rs.total_cost IS NOT NULL)
ORDER BY 
    nr.n_nationkey, rs.total_cost DESC;
