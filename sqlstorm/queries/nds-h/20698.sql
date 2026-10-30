WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1996-01-01' AND 
        o.o_orderdate < '1997-01-01'
),
HighValueOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_totalprice,
        ro.o_orderdate,
        p.p_name,
        s.s_name,
        ps.ps_supplycost,
        ps.ps_availqty,
        (ps.ps_supplycost * l.l_quantity) AS total_cost
    FROM 
        RankedOrders ro
    JOIN 
        lineitem l ON ro.o_orderkey = l.l_orderkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        ro.order_rank <= 10 AND
        l.l_discount BETWEEN 0.05 AND 0.1
),
AggregatedCosts AS (
    SELECT 
        hvo.o_orderkey,
        SUM(hvo.total_cost) AS total_order_cost,
        COUNT(*) AS part_count,
        MAX(hvo.ps_availqty) AS max_avail_qty
    FROM 
        HighValueOrders hvo
    GROUP BY 
        hvo.o_orderkey
),
FinalOutput AS (
    SELECT 
        ac.o_orderkey,
        ac.total_order_cost,
        ac.part_count,
        CASE 
            WHEN ac.max_avail_qty IS NULL THEN 'Unavailable' 
            ELSE 'Available' 
        END AS availability_status
    FROM 
        AggregatedCosts ac
)
SELECT 
    fo.o_orderkey,
    fo.total_order_cost,
    fo.part_count,
    fo.availability_status,
    COALESCE((SELECT MAX(o_totalprice) FROM orders WHERE o_orderkey = fo.o_orderkey), 0) AS max_total_price
FROM 
    FinalOutput fo
ORDER BY 
    fo.total_order_cost DESC NULLS LAST
LIMIT 100 OFFSET 0;
