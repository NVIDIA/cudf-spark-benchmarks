WITH SupplierPartStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
NationRegion AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name 
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_custkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
)
SELECT 
    n.n_name,
    SUM(COALESCE(s.total_avail_qty, 0)) AS total_available_qty,
    SUM(COALESCE(cos.total_orders, 0)) AS total_orders_by_nation,
    SUM(COALESCE(cos.total_spent, 0)) AS total_spent_by_nation,
    AVG(ro.order_rank) AS avg_order_rank
FROM 
    NationRegion n
LEFT JOIN 
    SupplierPartStats s ON n.n_nationkey = s.s_suppkey
LEFT JOIN 
    CustomerOrderStats cos ON n.n_nationkey = cos.c_custkey
LEFT JOIN 
    RankedOrders ro ON cos.c_custkey = ro.o_custkey
GROUP BY 
    n.n_name
ORDER BY 
    n.n_name;
