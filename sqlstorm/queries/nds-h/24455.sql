
WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_totalprice IS NOT NULL 
        AND o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
),
order_summary AS (
    SELECT 
        COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_sales,
        o.o_orderstatus,
        COUNT(DISTINCT l.l_orderkey) AS num_orders
    FROM 
        lineitem l
    LEFT JOIN 
        ranked_orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        l.l_shipdate IS NOT NULL 
        AND (l.l_returnflag = 'N' OR l.l_returnflag IS NULL)
    GROUP BY 
        o.o_orderstatus
),
supplier_info AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_qty
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        ps.ps_supplycost > 0
    GROUP BY 
        s.s_suppkey, s.s_name
),
final_output AS (
    SELECT 
        os.o_orderstatus,
        os.total_sales,
        os.num_orders,
        si.s_name,
        si.total_available_qty,
        ROW_NUMBER() OVER (PARTITION BY os.o_orderstatus ORDER BY os.total_sales DESC, si.total_available_qty DESC) AS ranked_supp
    FROM 
        order_summary os
    FULL OUTER JOIN 
        supplier_info si ON os.o_orderstatus IS NOT NULL AND si.total_available_qty IS NOT NULL
)
SELECT 
    fo.o_orderstatus,
    fo.total_sales,
    fo.num_orders,
    fo.s_name,
    fo.total_available_qty
FROM 
    final_output fo
WHERE 
    fo.ranked_supp < 5
    OR (fo.total_sales IS NULL AND fo.num_orders = 0)
ORDER BY 
    fo.o_orderstatus, fo.total_sales DESC;
