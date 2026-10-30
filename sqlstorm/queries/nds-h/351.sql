WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1998-01-01'
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS orders_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        COALESCE(o.orders_count, 0) AS orders_count,
        COALESCE(o.total_spent, 0) AS total_spent
    FROM 
        customer c
    LEFT JOIN CustomerOrders o ON c.c_custkey = o.c_custkey 
    WHERE 
        c.c_acctbal > 10000
),
AggregatedData AS (
    SELECT 
        r.r_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN supplier s ON l.l_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        l.l_shipdate >= DATE '1997-01-01' 
        AND l.l_shipdate < DATE '1998-01-01'
    GROUP BY 
        r.r_name
)
SELECT 
    hvc.c_custkey,
    hvc.c_name,
    hvc.orders_count,
    hvc.total_spent,
    ag.r_name AS region_name,
    ag.revenue,
    ag.order_count,
    ro.o_orderstatus,
    ro.o_totalprice,
    ro.order_rank
FROM 
    HighValueCustomers hvc
LEFT JOIN AggregatedData ag ON hvc.total_spent > 50000 
LEFT JOIN RankedOrders ro ON hvc.orders_count > 0 
WHERE 
    (ag.revenue IS NOT NULL OR hvc.total_spent > 0)
ORDER BY 
    hvc.total_spent DESC, 
    ag.revenue DESC;