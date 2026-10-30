WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        o.o_custkey,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
),
CustomerAggregation AS (
    SELECT 
        c.c_nationkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_nationkey
),
TopNations AS (
    SELECT 
        n.n_name,
        n.n_regionkey,
        SUM(ca.order_count) AS total_orders,
        SUM(ca.total_spent) AS total_revenue
    FROM 
        nation n
    JOIN 
        CustomerAggregation ca ON n.n_nationkey = ca.c_nationkey
    GROUP BY 
        n.n_name, n.n_regionkey
    ORDER BY 
        total_revenue DESC
    LIMIT 5
)
SELECT 
    tn.n_name,
    tn.total_orders,
    tn.total_revenue,
    r.r_name AS region_name,
    SUM(ps.ps_supplycost) AS total_supply_cost
FROM 
    TopNations tn
JOIN 
    region r ON tn.n_regionkey = r.r_regionkey
JOIN 
    partsupp ps ON ps.ps_availqty > 0
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
GROUP BY 
    tn.n_name, tn.total_orders, tn.total_revenue, region_name
ORDER BY 
    total_orders DESC;