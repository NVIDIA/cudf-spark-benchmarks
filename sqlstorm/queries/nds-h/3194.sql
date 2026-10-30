WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1997-12-31'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(ps.ps_partkey) AS parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 100000
),
HighValueOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ROW_NUMBER() OVER (ORDER BY ro.o_totalprice DESC) AS high_value_rank
    FROM 
        RankedOrders ro
    WHERE 
        ro.order_rank <= 10
)
SELECT 
    hvo.o_orderkey,
    hvo.o_orderdate,
    hvo.o_totalprice,
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_revenue,
    COUNT(DISTINCT l.l_partkey) AS unique_parts,
    ss.total_supply_cost,
    ss.parts_supplied
FROM 
    HighValueOrders hvo
LEFT JOIN 
    lineitem l ON hvo.o_orderkey = l.l_orderkey
LEFT JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
LEFT JOIN 
    SupplierStats ss ON ps.ps_suppkey = ss.s_suppkey
GROUP BY 
    hvo.o_orderkey, hvo.o_orderdate, hvo.o_totalprice, ss.total_supply_cost, ss.parts_supplied
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) IS NOT NULL
    AND total_supply_cost > 50000
ORDER BY 
    hvo.o_totalprice DESC;