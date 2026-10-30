WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
CustomerRevenue AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(ro.total_revenue) AS customer_revenue
    FROM 
        customer c
    JOIN 
        RankedOrders ro ON c.c_custkey = ro.o_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierPartDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_name
)
SELECT 
    cr.c_name AS customer_name,
    COALESCE(cr.customer_revenue, 0) AS total_revenue,
    COALESCE(spd.total_supply_cost, 0) AS total_supply_cost,
    COALESCE(cr.customer_revenue, 0) - COALESCE(spd.total_supply_cost, 0) AS net_profit
FROM 
    CustomerRevenue cr
FULL OUTER JOIN 
    SupplierPartDetails spd ON cr.c_custkey = spd.s_suppkey
WHERE 
    (cr.customer_revenue > 1000 OR spd.total_supply_cost IS NOT NULL)
ORDER BY 
    net_profit DESC
LIMIT 10;