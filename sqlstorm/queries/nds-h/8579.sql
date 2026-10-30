WITH supplier_part AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE 
        l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
        AND s.s_acctbal > 1000.00
), order_summary AS (
    SELECT 
        o.o_custkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_custkey
)
SELECT 
    sp.s_name,
    sp.p_name,
    sp.ps_availqty,
    os.total_orders,
    os.total_revenue,
    (sp.l_extendedprice * (1 - sp.l_discount)) AS revenue_per_item
FROM 
    supplier_part sp
JOIN 
    order_summary os ON sp.s_suppkey = os.o_custkey
ORDER BY 
    total_revenue DESC
LIMIT 10;