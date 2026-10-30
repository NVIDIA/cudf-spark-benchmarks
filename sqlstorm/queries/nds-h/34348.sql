
WITH  cte_order_summary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
cte_supplier_count AS (
    SELECT 
        p.p_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey
),
cte_nation_summary AS (
    SELECT 
        n.n_nationkey,
        COUNT(DISTINCT s.s_suppkey) AS total_suppliers
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey
),
final_summary AS (
    SELECT 
        os.o_orderkey,
        os.o_orderdate,
        COALESCE(cs.supplier_count, 0) AS supplier_count,
        COALESCE(ns.total_suppliers, 0) AS total_suppliers,
        os.total_revenue
    FROM 
        cte_order_summary os
    LEFT JOIN 
        cte_supplier_count cs ON os.o_orderkey = cs.p_partkey
    LEFT JOIN 
        cte_nation_summary ns ON cs.p_partkey = ns.n_nationkey
    WHERE 
        os.order_rank <= 10
)
SELECT 
    f.o_orderkey,
    f.o_orderdate,
    f.supplier_count,
    f.total_suppliers,
    f.total_revenue,
    CASE 
        WHEN f.total_revenue > 1000 THEN 'High Revenue'
        WHEN f.total_revenue BETWEEN 500 AND 1000 THEN 'Medium Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category
FROM 
    final_summary f
WHERE 
    f.supplier_count IS NOT NULL
ORDER BY 
    f.total_revenue DESC;
