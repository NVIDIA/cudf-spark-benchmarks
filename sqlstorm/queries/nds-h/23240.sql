WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31' 
        AND o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2 WHERE o2.o_orderdate < '1997-01-01')
), HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 100000
), OrderLineData AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_suppkey,
        l.l_linenumber,
        CASE 
            WHEN l.l_returnflag = 'R' THEN 'Returned'
            ELSE 'Sold'
        END AS sale_status,
        l.l_quantity,
        l.l_extendedprice - (l.l_extendedprice * l.l_discount) AS net_price
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= cast('1998-10-01' as date) - INTERVAL '90 days'
)

SELECT 
    r.o_orderkey,
    r.o_orderdate,
    COALESCE(SUM(ol.net_price), 0) AS total_order_value,
    COUNT(DISTINCT ol.l_orderkey) AS total_line_items,
    hs.s_name AS top_supplier
FROM 
    RankedOrders r
LEFT JOIN 
    OrderLineData ol ON r.o_orderkey = ol.l_orderkey
LEFT JOIN 
    HighValueSuppliers hs ON ol.l_suppkey = hs.s_suppkey
WHERE 
    r.order_rank <= 10
GROUP BY 
    r.o_orderkey, r.o_orderdate, hs.s_name
HAVING 
    COUNT(DISTINCT ol.l_linenumber) > 5 OR hs.s_name IS NOT NULL
ORDER BY 
    r.o_orderdate DESC, total_order_value DESC;