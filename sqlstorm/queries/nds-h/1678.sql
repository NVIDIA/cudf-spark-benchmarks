WITH ranked_suppliers AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
), total_sales AS (
    SELECT 
        l.l_partkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    GROUP BY 
        l.l_partkey
), high_revenue_parts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        tr.total_revenue,
        COALESCE(t.accounting_total, 0) AS accounting_total
    FROM 
        part p
    LEFT JOIN 
        total_sales tr ON p.p_partkey = tr.l_partkey
    LEFT JOIN (
        SELECT 
            ps.ps_partkey, 
            SUM(s.s_acctbal) AS accounting_total
        FROM 
            ranked_suppliers ps
        JOIN 
            supplier s ON ps.ps_suppkey = s.s_suppkey
        WHERE 
            ps.supplier_rank = 1
        GROUP BY 
            ps.ps_partkey
    ) t ON p.p_partkey = t.ps_partkey
    WHERE 
        tr.total_revenue > 1000
), selected_nations AS (
    SELECT 
        n.n_nationkey, 
        n.n_name
    FROM 
        nation n
    WHERE 
        n.n_name LIKE 'A%'
)

SELECT 
    hp.p_partkey,
    hp.p_name,
    hp.total_revenue,
    hp.accounting_total,
    n.n_name AS supplier_nation
FROM 
    high_revenue_parts hp
LEFT JOIN 
    partsupp ps ON hp.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    selected_nations n ON s.s_nationkey = n.n_nationkey
WHERE 
    n.n_nationkey IS NOT NULL
ORDER BY 
    hp.total_revenue DESC, hp.p_partkey;
