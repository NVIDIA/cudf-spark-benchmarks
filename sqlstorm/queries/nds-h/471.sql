WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
SupplierStats AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS parts_supplied,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.total_revenue,
    COALESCE(s.parts_supplied, 0) AS parts_supplied,
    COALESCE(s.total_cost, 0) AS total_cost,
    c.total_orders,
    c.total_spent,
    c.avg_order_value
FROM 
    RankedOrders r
FULL OUTER JOIN 
    SupplierStats s ON r.o_orderkey = s.s_suppkey
FULL OUTER JOIN 
    CustomerOrderStats c ON r.o_orderkey = c.total_orders
WHERE 
    (r.order_rank <= 10 OR s.parts_supplied > 5)
    AND (c.total_spent IS NOT NULL OR c.avg_order_value > 100)
ORDER BY 
    total_revenue DESC, total_cost ASC;
