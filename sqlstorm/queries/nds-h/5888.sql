WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        o.o_clerk,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1995-01-01' AND o.o_orderdate < '1996-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus, o.o_totalprice, o.o_orderdate, o.o_orderpriority, o.o_clerk
),
TopRevenueOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderstatus,
        ro.o_totalprice,
        ro.o_orderdate,
        ro.o_orderpriority,
        ro.o_clerk,
        ro.total_revenue
    FROM 
        RankedOrders ro
    WHERE 
        ro.revenue_rank <= 10
)
SELECT 
    t.o_orderkey,
    t.o_orderstatus,
    t.o_totalprice,
    t.o_orderdate,
    t.o_orderpriority,
    t.o_clerk,
    t.total_revenue,
    COUNT(DISTINCT l.l_partkey) AS distinct_parts_supplied
FROM 
    TopRevenueOrders t
JOIN 
    lineitem l ON t.o_orderkey = l.l_orderkey
GROUP BY 
    t.o_orderkey, t.o_orderstatus, t.o_totalprice, t.o_orderdate, t.o_orderpriority, t.o_clerk, t.total_revenue
ORDER BY 
    t.total_revenue DESC;
