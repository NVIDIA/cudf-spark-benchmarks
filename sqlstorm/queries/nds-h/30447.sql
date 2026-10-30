
WITH  top_suppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ROW_NUMBER() OVER (ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 5000
), 
total_revenue AS (
    SELECT 
        l.l_partkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND 
        o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        l.l_partkey
),
supplier_parts AS (
    SELECT 
        ps.ps_partkey, 
        s.s_suppkey, 
        SUM(ps.ps_availqty) AS total_availqty
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, s.s_suppkey
)
SELECT 
    p.p_partkey, 
    p.p_name, 
    COALESCE(sp.total_availqty, 0) AS available_quantity, 
    COALESCE(tr.revenue, 0) AS total_revenue,
    COALESCE(s.s_name, 'Unknown') AS supplier_name,
    r.r_name AS region_name
FROM 
    part p
LEFT JOIN 
    total_revenue tr ON p.p_partkey = tr.l_partkey
LEFT JOIN 
    supplier_parts sp ON p.p_partkey = sp.ps_partkey
LEFT JOIN 
    supplier s ON sp.s_suppkey = s.s_suppkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    (COALESCE(sp.total_availqty, 0) > 0 OR COALESCE(tr.revenue, 0) > 0)
AND 
    s.s_suppkey IN (SELECT s_suppkey FROM top_suppliers WHERE rank <= 10)
ORDER BY 
    COALESCE(tr.revenue, 0) DESC, 
    COALESCE(sp.total_availqty, 0) DESC
LIMIT 50;
