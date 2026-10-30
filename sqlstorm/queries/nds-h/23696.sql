WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank,
        COUNT(l.l_orderkey) OVER (PARTITION BY o.o_orderkey) AS lineitem_count
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
), 
customer_summary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus IN ('O', 'F')
    GROUP BY 
        c.c_custkey, c.c_name
), 
supplier_details AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        ps.ps_availqty > 0 
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    coalesce(NULLIF(cs.c_name, ''), 'Unknown Customer') AS customer_name,
    coalesce(NULLIF(so.o_orderstatus, 'N'), 'No Status') AS order_status,
    MAX(so.o_totalprice) AS max_order_value,
    AVG(sd.total_supply_cost) FILTER (WHERE sd.total_supply_cost IS NOT NULL) AS average_supply_cost,
    SUM(CASE WHEN lo.l_discount > 0 THEN lo.l_extendedprice * (1 - lo.l_discount) ELSE 0 END) AS total_discounted_value
FROM 
    ranked_orders so
FULL OUTER JOIN 
    customer_summary cs ON so.o_orderkey = cs.c_custkey
LEFT JOIN 
    lineitem lo ON so.o_orderkey = lo.l_orderkey
LEFT JOIN 
    supplier_details sd ON lo.l_suppkey = sd.s_suppkey
WHERE 
    so.order_rank <= 5 OR cs.total_spent > 1000
GROUP BY 
    customer_name, order_status
HAVING 
    MAX(so.o_totalprice) IS NOT NULL 
    AND AVG(sd.total_supply_cost) IS NOT NULL
ORDER BY 
    order_status DESC, max_order_value DESC;