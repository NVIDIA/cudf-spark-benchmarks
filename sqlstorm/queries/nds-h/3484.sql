
WITH supplier_info AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        n.n_name AS nation_name, 
        p.p_name AS part_name,
        COUNT(ps.ps_availqty) AS total_available_qty
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > 1000
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_name, p.p_name
),
order_summary AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(*) AS total_line_items
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O' 
        AND l.l_shipdate >= DATE '1997-01-01' 
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
ranked_orders AS (
    SELECT 
        os.o_orderkey, 
        os.o_orderdate, 
        os.total_revenue,
        os.total_line_items,
        RANK() OVER (ORDER BY os.total_revenue DESC) AS revenue_rank
    FROM 
        order_summary os
)
SELECT 
    si.s_name,
    si.nation_name,
    si.total_available_qty,
    ro.total_revenue,
    ro.o_orderdate,
    ro.total_line_items,
    CASE 
        WHEN ro.revenue_rank <= 10 THEN 'Top Revenue'
        ELSE 'Other Revenue' 
    END AS revenue_category
FROM 
    supplier_info si
LEFT JOIN 
    ranked_orders ro ON si.s_suppkey = ro.o_orderkey
WHERE 
    si.total_available_qty IS NOT NULL
ORDER BY 
    si.nation_name, ro.total_revenue DESC;
