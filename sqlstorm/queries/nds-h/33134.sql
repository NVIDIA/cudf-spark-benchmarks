
WITH  price_ranking AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
ranked_parts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.total_revenue,
        RANK() OVER (ORDER BY p.total_revenue DESC) AS revenue_rank
    FROM 
        price_ranking p
),
filtered_suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS supplier_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    r.p_partkey,
    r.p_name,
    r.total_revenue,
    s.s_suppkey,
    s.s_name,
    s.supplier_value
FROM 
    ranked_parts r
LEFT JOIN 
    filtered_suppliers s ON r.p_partkey = s.s_suppkey
WHERE 
    r.revenue_rank <= 10
    OR s.supplier_value IS NOT NULL
ORDER BY 
    r.total_revenue DESC, 
    s.supplier_value DESC;
