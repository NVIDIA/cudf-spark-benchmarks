
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        AVG(ps.ps_supplycost) > 50.00
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 1000.00 OR COUNT(DISTINCT o.o_orderkey) > 5
)
SELECT 
    co.c_name,
    r.r_name AS region,
    COALESCE(ss.total_available_qty, 0) AS supplier_qty,
    COALESCE(ss.avg_supply_cost, 0) AS supplier_cost,
    ro.order_rank,
    ro.o_totalprice
FROM 
    CustomerOrders co
LEFT JOIN 
    nation n ON co.c_custkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    SupplierStats ss ON r.r_regionkey = ss.s_suppkey
LEFT JOIN 
    RankedOrders ro ON co.order_count = ro.order_rank
WHERE 
    COALESCE(ss.total_available_qty, 0) > 0
ORDER BY 
    co.total_spent DESC, ro.o_orderdate;
