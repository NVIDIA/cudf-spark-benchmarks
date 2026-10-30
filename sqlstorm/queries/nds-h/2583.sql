WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
HighRevenueOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.total_revenue
    FROM 
        RankedOrders ro
    WHERE 
        ro.revenue_rank <= 10
),
SuppliersWithHighRevenue AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        ps.ps_availqty > 100
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 5000
)
SELECT 
    cu.c_name,
    cu.c_acctbal,
    swh.total_supply_cost,
    hro.total_revenue,
    CASE 
        WHEN cu.c_acctbal IS NULL THEN 'No Account Balance'
        ELSE 'Account Balance Available'
    END AS Account_Status
FROM 
    customer cu
LEFT JOIN 
    HighRevenueOrders hro ON cu.c_custkey = hro.o_orderkey
LEFT JOIN 
    SuppliersWithHighRevenue swh ON swh.total_supply_cost = (
        SELECT MAX(total_supply_cost) 
        FROM SuppliersWithHighRevenue
    )
WHERE 
    cu.c_mktsegment = 'BUILDING'
    OR (cu.c_acctbal IS NULL AND hro.total_revenue IS NOT NULL)
ORDER BY 
    cu.c_name ASC, hro.total_revenue DESC;
