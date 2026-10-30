
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
TopOrders AS (
    SELECT 
        r.o_orderkey,
        r.o_orderdate,
        r.total_revenue
    FROM 
        RankedOrders r
    WHERE 
        r.order_rank <= 10
),
CustomerRevenue AS (
    SELECT 
        c.c_name,
        SUM(t.total_revenue) AS customer_revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        TopOrders t ON o.o_orderkey = t.o_orderkey
    GROUP BY 
        c.c_name
)
SELECT 
    cr.c_name,
    cr.customer_revenue,
    r.r_name,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
FROM 
    CustomerRevenue cr
JOIN 
    supplier s ON cr.c_name LIKE CONCAT('%', s.s_name, '%') 
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
GROUP BY 
    cr.c_name, cr.customer_revenue, r.r_name
HAVING 
    SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
ORDER BY 
    cr.customer_revenue DESC, total_supply_cost ASC;
