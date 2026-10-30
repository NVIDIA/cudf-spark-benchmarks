WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        DENSE_RANK() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM
        orders AS o
    JOIN
        lineitem AS l ON o.o_orderkey = l.l_orderkey
    GROUP BY
        o.o_orderkey, o.o_orderdate
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent,
        ROW_NUMBER() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS spending_rank
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
SupplySummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS average_supply_cost
    FROM 
        supplier AS s
    JOIN 
        partsupp AS ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    r.r_name AS region,
    o.o_orderkey,
    o.o_orderdate,
    c.c_name AS customer_name,
    tc.total_spent,
    ss.total_available,
    ss.average_supply_cost,
    ro.total_revenue
FROM 
    RankedOrders AS ro
JOIN 
    orders AS o ON ro.o_orderkey = o.o_orderkey
JOIN 
    customer AS c ON o.o_custkey = c.c_custkey
JOIN 
    TopCustomers AS tc ON c.c_custkey = tc.c_custkey
JOIN 
    nation AS n ON c.c_nationkey = n.n_nationkey
JOIN 
    region AS r ON n.n_regionkey = r.r_regionkey
JOIN 
    SupplySummary AS ss ON ss.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp AS ps ORDER BY ps.ps_supplycost ASC LIMIT 1)
WHERE 
    ro.revenue_rank <= 10
ORDER BY 
    region, total_spent DESC;
