
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        RANK() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopRevenueOrders AS (
    SELECT 
        r.o_orderkey,
        r.o_orderdate,
        r.revenue
    FROM 
        RankedOrders r
    WHERE 
        r.rank <= 10
),
CustomerOrderDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        t.revenue,
        o.o_orderdate
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        TopRevenueOrders t ON o.o_orderkey = t.o_orderkey
)
SELECT 
    cod.c_custkey,
    cod.c_name,
    SUM(cod.revenue) AS total_revenue,
    COUNT(DISTINCT cod.o_orderdate) AS order_count
FROM 
    CustomerOrderDetails cod
GROUP BY 
    cod.c_custkey, cod.c_name
ORDER BY 
    total_revenue DESC
LIMIT 5;
