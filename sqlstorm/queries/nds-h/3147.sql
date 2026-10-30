WITH SupplierData AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_orderdate,
        o.o_totalprice,
        o.o_shippriority,
        os.total_revenue
    FROM 
        orders o
    JOIN 
        OrderSummary os ON o.o_orderkey = os.o_orderkey
    WHERE 
        os.revenue_rank <= 10
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(sd.total_avail_qty, 0) AS total_available_quantity,
    COALESCE(sd.avg_supply_cost, 0) AS average_supply_cost,
    hvo.o_orderkey,
    hvo.o_totalprice,
    hvo.o_orderdate,
    hvo.o_shippriority
FROM 
    part p
LEFT JOIN 
    SupplierData sd ON p.p_partkey = sd.s_suppkey
LEFT JOIN 
    HighValueOrders hvo ON p.p_partkey = hvo.o_orderkey
WHERE 
    (sd.total_avail_qty IS NOT NULL AND sd.total_avail_qty > 100) OR
    (hvo.o_orderkey IS NOT NULL AND hvo.o_shippriority >= 5)
ORDER BY 
    p.p_partkey, hvo.o_orderdate DESC;