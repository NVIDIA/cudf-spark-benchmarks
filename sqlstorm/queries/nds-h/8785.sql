WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
CustomerOrderInfo AS (
    SELECT 
        c.c_name,
        c.c_acctbal,
        ro.o_orderkey,
        ro.o_orderdate,
        ro.revenue,
        ro.revenue_rank
    FROM 
        Customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        RankedOrders ro ON o.o_orderkey = ro.o_orderkey
)
SELECT 
    coi.c_name AS customer_name,
    coi.c_acctbal AS account_balance,
    coi.o_orderdate AS order_date,
    coi.revenue AS total_revenue,
    coi.revenue_rank AS rank_within_date
FROM 
    CustomerOrderInfo coi
WHERE 
    coi.revenue_rank <= 5
ORDER BY 
    coi.o_orderdate,
    coi.revenue DESC;
