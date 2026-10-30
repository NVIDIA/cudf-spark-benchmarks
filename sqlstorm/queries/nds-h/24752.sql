
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND 
        o.o_orderdate < DATE '1997-01-01'
), SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) OVER (PARTITION BY s.s_suppkey) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
), LineitemStats AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS item_count
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
), OrderSummary AS (
    SELECT 
        ro.o_orderkey,
        ro.o_totalprice,
        COALESCE(ls.total_revenue, 0) AS total_revenue,
        COALESCE(ls.item_count, 0) AS item_count
    FROM 
        RankedOrders ro
    LEFT JOIN 
        LineitemStats ls ON ro.o_orderkey = ls.l_orderkey
    WHERE 
        ro.rn = 1
), SupplierRegion AS (
    SELECT 
        rd.r_name,
        sd.s_name,
        CASE 
            WHEN sd.total_supply_value IS NULL THEN 'NOT SUPPLIED'
            ELSE CAST(sd.total_supply_value AS STRING)
        END AS supply_status
    FROM 
        SupplierDetails sd
    LEFT JOIN 
        nation n ON sd.s_nationkey = n.n_nationkey
    JOIN 
        region rd ON n.n_regionkey = rd.r_regionkey
    WHERE 
        sd.total_supply_value > (SELECT AVG(ps_supplycost) FROM partsupp)
)

SELECT 
    sr.r_name,
    sr.s_name,
    COUNT(DISTINCT os.o_orderkey) AS total_orders,
    AVG(os.total_revenue) AS avg_order_revenue,
    SUM(CASE WHEN sr.supply_status = 'NOT SUPPLIED' THEN 1 ELSE 0 END) AS unsupplied_count
FROM 
    SupplierRegion sr
LEFT JOIN 
    OrderSummary os ON sr.s_name LIKE CONCAT('%', CAST(os.o_totalprice AS STRING), '%')
GROUP BY 
    sr.r_name, sr.s_name
HAVING 
    COUNT(DISTINCT os.o_orderkey) > 5
ORDER BY 
    avg_order_revenue DESC, sr.s_name ASC;
