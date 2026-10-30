WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderstatus IN ('O', 'F')
),
supplier_summary AS (
    SELECT 
        s.s_nationkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(s.s_acctbal) AS avg_acctbal
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_nationkey
),
lineitem_summary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(*) AS item_count,
        MAX(l.l_shipdate) AS last_ship_date
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    n.n_name,
    COALESCE(ss.total_avail_qty, 0) AS total_avail_qty,
    COALESCE(ss.avg_acctbal, 0) AS avg_acctbal,
    COALESCE(ls.total_revenue, 0) AS total_revenue,
    lo.o_orderkey,
    lo.o_orderdate
FROM 
    nation n
LEFT JOIN 
    supplier_summary ss ON n.n_nationkey = ss.s_nationkey
LEFT JOIN 
    lineitem_summary ls ON ls.l_orderkey IN (SELECT DISTINCT o_orderkey FROM ranked_orders WHERE rn <= 10)
LEFT JOIN 
    ranked_orders lo ON lo.o_orderkey = ls.l_orderkey
WHERE 
    n.n_regionkey IS NOT NULL
ORDER BY 
    total_revenue DESC, total_avail_qty ASC;