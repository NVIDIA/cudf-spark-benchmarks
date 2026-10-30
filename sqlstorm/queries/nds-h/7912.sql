
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders AS o
    JOIN 
        lineitem AS l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '5 YEAR'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM 
        customer AS c
    JOIN 
        orders AS o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem AS l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
HighValueParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp AS ps
    GROUP BY 
        ps.ps_partkey
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 50000
)
SELECT 
    r.r_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(lt.total_revenue) AS total_revenue_generated,
    SUM(cv.total_spent) AS total_customer_spending,
    SUM(hp.total_supply_cost) AS total_supply_cost
FROM 
    region AS r
JOIN 
    nation AS n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier AS s ON n.n_nationkey = s.s_nationkey
JOIN 
    partsupp AS ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    lineitem AS l ON ps.ps_partkey = l.l_partkey
JOIN 
    orders AS o ON l.l_orderkey = o.o_orderkey
JOIN 
    RankedOrders AS lt ON o.o_orderkey = lt.o_orderkey
JOIN 
    TopCustomers AS cv ON o.o_custkey = cv.c_custkey
JOIN 
    HighValueParts AS hp ON ps.ps_partkey = hp.ps_partkey
WHERE 
    o.o_orderdate >= CURRENT_DATE - INTERVAL '2 YEAR'
GROUP BY 
    r.r_name
ORDER BY 
    total_revenue_generated DESC
LIMIT 10;
