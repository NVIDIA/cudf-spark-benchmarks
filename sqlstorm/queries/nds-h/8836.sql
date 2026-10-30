WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND 
        o.o_orderdate < DATE '1998-01-01'
),
OrderLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_orderkey) AS total_items
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
),
AggregatedMetrics AS (
    SELECT 
        r.o_orderkey,
        r.o_orderdate,
        r.c_name,
        r.c_acctbal,
        l.total_revenue,
        l.total_items
    FROM 
        RankedOrders r
    JOIN 
        OrderLineItems l ON r.o_orderkey = l.l_orderkey
    WHERE 
        r.order_rank <= 10
)
SELECT 
    a.o_orderkey, 
    a.o_orderdate,
    a.c_name,
    a.c_acctbal,
    a.total_revenue,
    a.total_items,
    r.r_name AS customer_region,
    s.s_name AS supplier_name
FROM 
    AggregatedMetrics a
JOIN 
    supplier s ON a.total_items > 5
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
ORDER BY 
    a.total_revenue DESC, 
    a.o_orderdate ASC
LIMIT 20;