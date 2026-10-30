WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-10-01'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    c.c_name,
    co.order_count,
    co.total_spent,
    COUNT(DISTINCT lo.l_orderkey) AS distinct_orders,
    SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_revenue,
    s.total_available AS supplier_avail_qty,
    s.avg_supply_cost AS supplier_avg_cost
FROM 
    CustomerOrders co
JOIN 
    customer c ON co.c_custkey = c.c_custkey
LEFT JOIN 
    lineitem lo ON c.c_custkey = lo.l_suppkey
LEFT JOIN 
    SupplierStats s ON lo.l_suppkey = s.s_suppkey
WHERE 
    co.order_count > 5 
    AND co.total_spent > 1000 
    AND lo.l_shipdate IS NOT NULL 
    AND s.total_available IS NOT NULL
GROUP BY 
    c.c_name, co.order_count, co.total_spent, s.total_available, s.avg_supply_cost
HAVING 
    SUM(lo.l_extendedprice * (1 - lo.l_discount)) > 5000
ORDER BY 
    total_revenue DESC;