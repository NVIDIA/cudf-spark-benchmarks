WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
supplier_part AS (
    SELECT
        p.p_partkey, 
        s.s_suppkey, 
        COALESCE(SUM(ps.ps_availqty), 0) AS total_avail_qty
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey, s.s_suppkey
),
filtered_suppliers AS (
    SELECT 
        sp.p_partkey,
        sp.s_suppkey,
        sp.total_avail_qty
    FROM 
        supplier_part sp
    WHERE 
        sp.total_avail_qty > (
            SELECT 
                AVG(sp_inner.total_avail_qty) 
            FROM 
                supplier_part sp_inner
            WHERE 
                sp_inner.p_partkey = sp.p_partkey
        )
),
distinct_nations AS (
    SELECT DISTINCT 
        n.n_name
    FROM 
        nation n
    WHERE 
        n.n_regionkey IS NOT NULL
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.total_revenue,
    fs.p_partkey,
    fs.s_suppkey,
    fs.total_avail_qty,
    dn.n_name AS distinct_nation
FROM 
    ranked_orders ro
LEFT JOIN 
    filtered_suppliers fs ON ro.o_orderkey = fs.s_suppkey
JOIN 
    customer c ON ro.o_orderkey = c.c_custkey
CROSS JOIN 
    distinct_nations dn
WHERE 
    ro.total_revenue > 1000.00
    AND (c.c_acctbal IS NOT NULL OR c.c_name LIKE 'A%')
ORDER BY 
    ro.total_revenue DESC, dn.n_name ASC
LIMIT 10;

