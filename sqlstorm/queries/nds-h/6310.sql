WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopNations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        n.n_nationkey, n.n_name
    ORDER BY 
        total_supply_cost DESC
    LIMIT 5
)
SELECT 
    rn.o_orderkey,
    rn.o_orderdate,
    tn.n_name,
    rn.total_revenue,
    tn.total_supply_cost
FROM 
    RankedOrders rn
JOIN 
    TopNations tn ON rn.o_orderkey % 5 = tn.n_nationkey % 5
ORDER BY 
    rn.total_revenue DESC, tn.total_supply_cost ASC;
