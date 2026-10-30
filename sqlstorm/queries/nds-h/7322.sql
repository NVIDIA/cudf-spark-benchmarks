WITH Supplier_Order_Summary AS (
    SELECT 
        s.s_name AS supplier_name,
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        AVG(l.l_quantity) AS avg_quantity_per_order,
        AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_revenue_per_order
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        l.l_shipdate > DATE '1995-01-01' 
        AND l.l_shipdate < DATE '1996-12-31'
    GROUP BY 
        s.s_name, n.n_name
)
SELECT 
    supplier_name,
    nation_name,
    total_revenue,
    total_orders,
    avg_quantity_per_order,
    avg_revenue_per_order,
    ROW_NUMBER() OVER (PARTITION BY nation_name ORDER BY total_revenue DESC) AS revenue_rank
FROM 
    Supplier_Order_Summary
ORDER BY 
    nation_name, total_revenue DESC;
