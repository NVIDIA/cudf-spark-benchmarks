WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
SupplierAvailability AS (
    SELECT 
        p.p_partkey,
        COALESCE(SUM(ps.ps_availqty), 0) AS total_available
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey
),
CustomerSegment AS (
    SELECT 
        c.c_custkey,
        c.c_mktsegment,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_mktsegment
),
BizarreJoin AS (
    SELECT 
        s.s_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        MAX(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS returned_quantity,
        MIN(CASE WHEN l.l_linestatus = 'O' THEN l.l_discount END) AS lowest_open_discount
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        s.s_name
)
SELECT 
    r.o_orderkey,
    r.total_revenue,
    sa.total_available,
    cs.c_mktsegment,
    bz.order_count,
    bz.returned_quantity,
    bz.lowest_open_discount
FROM 
    RankedOrders r
JOIN 
    SupplierAvailability sa ON r.o_orderkey = sa.p_partkey
JOIN 
    CustomerSegment cs ON r.o_orderkey IN (SELECT o_orderkey FROM orders WHERE o_custkey IS NULL OR o_orderstatus = 'F')
LEFT JOIN 
    BizarreJoin bz ON bz.order_count > 0 AND r.o_orderkey NOT IN (SELECT o_orderkey FROM orders WHERE o_orderstatus = 'C')
WHERE 
    r.revenue_rank <= 5
ORDER BY 
    r.total_revenue DESC, cs.total_orders ASC;
