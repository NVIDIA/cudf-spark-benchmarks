WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_mktsegment,
        RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
),
TopOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_totalprice,
        ro.c_mktsegment
    FROM 
        RankedOrders ro
    WHERE 
        ro.order_rank <= 10
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
PartStats AS (
    SELECT 
        p.p_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        SUM(l.l_extendedprice) AS total_revenue
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey
)
SELECT 
    o.o_orderkey,
    o.o_totalprice,
    o.c_mktsegment,
    ps.supplier_count,
    ps.total_revenue,
    ss.total_supply_cost
FROM 
    TopOrders o
JOIN 
    PartStats ps ON o.o_orderkey = ps.p_partkey
JOIN 
    SupplierStats ss ON ps.supplier_count > 0
ORDER BY 
    o.o_totalprice DESC, 
    ps.total_revenue DESC
LIMIT 100;