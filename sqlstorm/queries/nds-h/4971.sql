WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' 
        AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
), filtered_orders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.total_revenue
    FROM 
        ranked_orders ro
    WHERE 
        ro.order_rank = 1
), supplier_data AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    fo.o_orderkey,
    fo.o_orderdate,
    fo.total_revenue,
    sd.s_name,
    COALESCE(NULLIF(sd.total_supply_cost, 0), 1) AS adjusted_supply_cost,
    CONCAT(fo.o_orderkey, ' - ', sd.s_name) AS order_supplier_info
FROM 
    filtered_orders fo
LEFT JOIN 
    supplier_data sd ON fo.o_orderkey % 10 = sd.s_suppkey % 10
WHERE 
    fo.total_revenue > (SELECT AVG(total_revenue) FROM filtered_orders)
ORDER BY 
    fo.total_revenue DESC
LIMIT 100;