WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        c.c_name,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
HighValueOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.c_name,
        ss.total_avail_qty,
        ss.avg_supply_cost
    FROM 
        RankedOrders ro
    LEFT JOIN 
        lineitem l ON ro.o_orderkey = l.l_orderkey
    LEFT JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        SupplierStats ss ON ps.ps_suppkey = ss.s_suppkey
    WHERE 
        ro.order_rank = 1
        AND (ss.total_avail_qty IS NOT NULL OR ss.avg_supply_cost < 10.00)
)
SELECT 
    hvo.o_orderkey,
    hvo.o_orderdate,
    hvo.o_totalprice,
    hvo.c_name,
    COALESCE(hvo.total_avail_qty, 0) AS availability,
    ROUND(hvo.avg_supply_cost, 2) AS average_cost,
    CASE 
        WHEN hvo.avg_supply_cost IS NULL THEN 'Cost Data Unavailable' 
        ELSE 'Cost Available' 
    END AS cost_status
FROM 
    HighValueOrders hvo
WHERE 
    hvo.o_totalprice > (SELECT AVG(o_totalprice) FROM RankedOrders) 
ORDER BY 
    hvo.o_orderdate DESC, 
    hvo.o_totalprice DESC;