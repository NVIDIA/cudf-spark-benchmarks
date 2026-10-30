WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
nation_supplier AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS total_suppliers
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
),
top_nations AS (
    SELECT 
        ns.n_nationkey,
        ns.n_name,
        ns.total_suppliers,
        ROW_NUMBER() OVER (ORDER BY ns.total_suppliers DESC) AS nation_rank
    FROM 
        nation_supplier ns
    WHERE 
        ns.total_suppliers > 0
)

SELECT 
    r.o_orderkey,
    r.o_orderdate,
    COALESCE(tn.n_name, 'Other') AS nation_name,
    r.total_revenue,
    CASE 
        WHEN r.order_rank = 1 THEN 'Top Order'
        ELSE 'Regular Order'
    END AS order_category
FROM 
    ranked_orders r
LEFT JOIN 
    top_nations tn ON r.o_orderkey % 10 = tn.n_nationkey
WHERE 
    r.total_revenue > (SELECT AVG(total_revenue) FROM ranked_orders)
ORDER BY 
    r.o_orderdate DESC, r.total_revenue DESC;
