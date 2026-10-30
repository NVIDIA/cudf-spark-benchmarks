
WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank,
        (SELECT COUNT(*) FROM lineitem li WHERE li.l_orderkey = o.o_orderkey) AS line_count
    FROM 
        orders o
    WHERE 
        o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2 WHERE o2.o_orderstatus = o.o_orderstatus)
),
supplier_totals AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_suppkey
),
order_line_items AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_value,
        CASE 
            WHEN SUM(l.l_quantity) = 0 THEN 'Zero Quantity'
            WHEN SUM(l.l_quantity) < 0 THEN 'Negative Quantity'
            ELSE 'Valid Quantity'
        END AS quantity_status
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    r.order_rank,
    ol.total_line_value,
    st.total_supply_cost,
    COALESCE(ol.quantity_status, 'Unknown') AS quantity_status,
    CASE 
        WHEN r.line_count IS NULL THEN 'LINEITEMS MISSING'
        ELSE 'LINEITEMS PRESENT'
    END AS line_item_status,
    RANK() OVER (PARTITION BY COALESCE(n.n_name, 'Unknown Nation') ORDER BY r.o_totalprice DESC) AS nationwide_rank
FROM 
    ranked_orders r
LEFT JOIN 
    order_line_items ol ON r.o_orderkey = ol.o_orderkey
LEFT JOIN 
    supplier_totals st ON r.o_orderkey % (SELECT COUNT(*) FROM supplier) = st.ps_suppkey
LEFT JOIN 
    customer c ON r.o_orderkey = c.c_custkey 
LEFT JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
WHERE 
    (r.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31' OR r.line_count IS NULL)
    AND r.order_rank <= 10 
    AND (n.n_name IS NOT NULL OR n.n_name IS NULL) 
ORDER BY 
    r.o_orderdate DESC, 
    r.o_totalprice ASC;
