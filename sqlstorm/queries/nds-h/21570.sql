
WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
), 
supplier_parts AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        SUM(ps.ps_availqty) AS total_available, 
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
), 
order_line_items AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_suppkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        COALESCE(NULLIF(l.l_shipdate, l.l_commitdate), l.l_receiptdate) AS effective_shipdate
    FROM 
        lineitem l
)
SELECT 
    o.o_orderkey,
    o.o_orderstatus,
    COALESCE(SUM(ol.l_extendedprice * (1 - ol.l_discount)), 0) AS total_revenue,
    COUNT(DISTINCT ol.l_partkey) AS unique_parts,
    COUNT(DISTINCT ol.l_suppkey) AS unique_suppliers,
    CASE 
        WHEN o.o_orderstatus = 'F' THEN 'Finalized'
        ELSE 'Pending'
    END AS order_status_description,
    CASE 
        WHEN o.o_totalprice > 10000 THEN 'High Value'
        ELSE 'Standard Value'
    END AS total_price_category
FROM 
    ranked_orders o
LEFT JOIN 
    order_line_items ol ON o.o_orderkey = ol.l_orderkey
LEFT JOIN 
    supplier_parts sp ON ol.l_partkey = sp.ps_partkey AND ol.l_suppkey = sp.ps_suppkey
WHERE 
    sp.total_available IS NOT NULL
    AND (sp.avg_supplycost < 50.00 OR sp.avg_supplycost IS NULL)
GROUP BY 
    o.o_orderkey, o.o_orderstatus, o.o_totalprice, o.o_orderdate
HAVING 
    SUM(ol.l_quantity) > 0
ORDER BY 
    total_revenue DESC, o.o_orderkey
LIMIT 100;
