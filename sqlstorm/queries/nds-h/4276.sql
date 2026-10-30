WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1998-01-01'
), 
SupplierAvailability AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY
        ps.ps_partkey
), 
OrderLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(l.l_linenumber) AS line_count
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)

SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    s.total_avail_qty,
    s.avg_supply_cost,
    o.total_price AS line_item_total,
    COALESCE(s.total_avail_qty, 0) - COALESCE(o.line_count, 0) AS available_after_order,
    CASE 
        WHEN r.order_rank <= 5 THEN 'Top Order'
        ELSE 'Regular Order'
    END AS order_type
FROM 
    RankedOrders r
LEFT JOIN 
    SupplierAvailability s ON s.ps_partkey = (
        SELECT ps.ps_partkey 
        FROM partsupp ps 
        WHERE ps.ps_availqty > 0 
        ORDER BY ps.ps_supplycost ASC 
        LIMIT 1
    )
LEFT JOIN 
    OrderLineItems o ON r.o_orderkey = o.l_orderkey
WHERE 
    r.o_totalprice > (SELECT AVG(o_totalprice) FROM orders)
ORDER BY 
    r.o_orderdate DESC, 
    r.o_totalprice DESC;