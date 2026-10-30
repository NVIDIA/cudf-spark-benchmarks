
WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
top_orders AS (
    SELECT 
        o.o_orderkey AS orderkey, 
        o.o_orderdate AS orderdate, 
        o.total_revenue
    FROM 
        ranked_orders o
    WHERE 
        o.revenue_rank <= 10
),
supplier_details AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_retailprice > 100.00
),
revenue_by_supplier AS (
    SELECT 
        s.s_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS supplier_revenue
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        s.s_suppkey
)
SELECT 
    s.s_name,
    s.s_acctbal,
    SUM(t.total_revenue) AS associated_revenue,
    SUM(r.supplier_revenue) AS supplier_total_revenue
FROM 
    supplier_details s
LEFT JOIN 
    top_orders t ON t.orderkey = t.orderkey
LEFT JOIN 
    revenue_by_supplier r ON s.s_suppkey = r.s_suppkey
GROUP BY 
    s.s_suppkey, s.s_name, s.s_acctbal
ORDER BY 
    associated_revenue DESC, supplier_total_revenue DESC
LIMIT 20;
