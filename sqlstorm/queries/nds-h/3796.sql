WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
LineItemSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_suppkey) AS supplier_count
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate > cast('1998-10-01' as date) - INTERVAL '30 days'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    r.o_orderstatus,
    COALESCE(lp.total_revenue, 0) AS total_revenue,
    COALESCE(sp.total_avail_qty, 0) AS total_avail_qty,
    COALESCE(sp.avg_supply_cost, 0) AS avg_supply_cost,
    CASE 
        WHEN r.o_orderstatus = 'O' THEN 'Order is Open'
        WHEN r.o_orderstatus = 'F' THEN 'Order is Finished'
        ELSE 'Other Status'
    END AS order_status_description
FROM 
    RankedOrders r
LEFT JOIN 
    LineItemSummary lp ON r.o_orderkey = lp.l_orderkey
LEFT JOIN 
    SupplierParts sp ON sp.ps_partkey IN (
        SELECT ps.ps_partkey 
        FROM partsupp ps 
        JOIN supplier s ON ps.ps_suppkey = s.s_suppkey 
        WHERE s.s_nationkey = (
            SELECT n.n_nationkey 
            FROM nation n 
            WHERE n.n_name = 'GERMANY'
        )
    )
WHERE 
    r.rn <= 10
ORDER BY 
    r.o_orderdate DESC;