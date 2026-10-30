WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN '1995-01-01' AND '1996-12-31'
), SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), CustomerStats AS (
    SELECT 
        c.c_custkey,
        SUM(CASE WHEN o.o_orderstatus = 'O' THEN o.o_totalprice ELSE 0 END) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
), RecentShipments AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_shipping_revenue
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= cast('1998-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    ns.n_name,
    COUNT(DISTINCT co.c_custkey) AS num_customers,
    SUM(COALESCE(so.avg_supply_cost, 0)) AS total_avg_supply_cost,
    SUM(CASE WHEN ro.order_rank <= 10 THEN ro.o_totalprice ELSE 0 END) AS top_orders_total,
    MAX(rs.total_shipping_revenue) AS max_shipment_revenue
FROM 
    nation ns
LEFT JOIN 
    supplier s ON ns.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierSummary so ON s.s_suppkey = so.s_suppkey
LEFT JOIN 
    CustomerStats co ON ns.n_nationkey = co.c_custkey
LEFT JOIN 
    RankedOrders ro ON co.c_custkey = ro.o_orderkey
LEFT JOIN 
    RecentShipments rs ON ro.o_orderkey = rs.l_orderkey
GROUP BY 
    ns.n_name
HAVING 
    SUM(CASE WHEN LENGTH(ns.n_name) > 5 THEN 1 ELSE 0 END) > 0
ORDER BY 
    total_avg_supply_cost DESC NULLS LAST;