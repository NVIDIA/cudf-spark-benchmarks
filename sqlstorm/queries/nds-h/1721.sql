WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus IN ('O', 'F')
),
SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
DiscountedLineitems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_discounted_price,
        COUNT(*) AS item_count
    FROM 
        lineitem l
    WHERE 
        l.l_discount > 0.1
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.o_orderkey,
    r.o_orderstatus,
    r.o_totalprice,
    d.total_discounted_price,
    COALESCE(s.total_available_qty, 0) AS total_available_qty,
    COALESCE(s.avg_supply_cost, 0) AS avg_supply_cost,
    s.part_count,
    RANK() OVER (ORDER BY r.o_totalprice DESC) AS order_price_rank
FROM 
    RankedOrders r
LEFT JOIN 
    DiscountedLineitems d ON r.o_orderkey = d.l_orderkey
LEFT JOIN 
    SupplierSummary s ON r.o_orderkey = s.s_suppkey
WHERE 
    r.order_rank <= 5
AND 
    (s.part_count > 2 OR s.part_count IS NULL)
ORDER BY 
    r.o_orderstatus, r.o_orderkey;
