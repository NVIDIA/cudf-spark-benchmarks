WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
), 
PartStats AS (
    SELECT 
        p.p_partkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS num_parts_supplied,
        SUM(s.s_acctbal) AS total_account_balance
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    ps.p_partkey,
    ps.total_available,
    ps.avg_supply_cost,
    ss.num_parts_supplied,
    ss.total_account_balance
FROM 
    RankedOrders r
LEFT JOIN 
    lineitem l ON r.o_orderkey = l.l_orderkey
LEFT JOIN 
    PartStats ps ON l.l_partkey = ps.p_partkey
LEFT JOIN 
    SupplierStats ss ON l.l_suppkey = ss.s_suppkey
WHERE 
    (r.order_rank = 1 OR r.order_rank IS NULL)
    AND (ps.total_available IS NOT NULL AND ps.avg_supply_cost < 50.00)
ORDER BY 
    r.o_orderdate DESC, 
    ps.avg_supply_cost DESC
LIMIT 100;