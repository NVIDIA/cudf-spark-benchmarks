WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
),
SupplierPartInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        p.p_container,
        ps.ps_supplycost,
        ps.ps_availqty,
        s.s_acctbal,
        COALESCE(NULLIF(s.s_comment, ''), 'No comments provided') AS comment
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > 0
),
OrderLineInfo AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(*) AS line_count,
        MAX(l.l_shipdate) AS last_ship_date,
        SUM(l.l_quantity) AS total_quantity
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice,
    ro.o_orderpriority,
    spi.s_name,
    spi.p_name,
    spi.ps_availqty,
    oli.total_revenue,
    CASE 
        WHEN oli.total_revenue > 10000 THEN 'High Revenue'
        WHEN oli.total_revenue BETWEEN 5000 AND 10000 THEN 'Medium Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category,
    oli.last_ship_date,
    spi.comment
FROM 
    RankedOrders ro
LEFT JOIN 
    OrderLineInfo oli ON ro.o_orderkey = oli.l_orderkey
LEFT JOIN 
    SupplierPartInfo spi ON oli.l_orderkey = spi.p_partkey
WHERE 
    (ro.o_orderpriority = 'HIGH' OR ro.o_orderpriority = 'MEDIUM')
    AND spi.ps_availqty > 0
ORDER BY 
    ro.o_totalprice DESC, 
    spi.p_name ASC;