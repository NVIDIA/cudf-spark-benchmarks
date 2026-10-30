
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        SUM(r.total_revenue) AS customer_revenue
    FROM 
        customer c
    JOIN 
        RankedOrders r ON c.c_custkey = r.o_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_acctbal
)
SELECT 
    cs.c_custkey,
    cs.c_name,
    cs.c_acctbal,
    cs.customer_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    MAX(r.o_orderdate) AS last_order_date
FROM 
    CustomerSummary cs
JOIN 
    orders o ON cs.c_custkey = o.o_custkey
JOIN 
    RankedOrders r ON o.o_orderkey = r.o_orderkey
WHERE 
    cs.customer_revenue > 10000
GROUP BY 
    cs.c_custkey, cs.c_name, cs.c_acctbal, cs.customer_revenue
ORDER BY 
    cs.customer_revenue DESC, order_count DESC;
