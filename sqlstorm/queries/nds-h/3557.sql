WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_suppkey) AS supplier_count,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, c.c_name, c.c_nationkey
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopCustomers AS (
    SELECT 
        r.o_orderkey, 
        r.c_name, 
        r.total_revenue
    FROM 
        RankedOrders r
    WHERE 
        r.revenue_rank <= 5
),
MaxAvgSupplyCost AS (
    SELECT 
        MAX(avg_supply_cost) AS max_supply_cost
    FROM 
        FilteredSuppliers
)
SELECT 
    tc.o_orderkey,
    tc.c_name,
    tc.total_revenue,
    fs.s_name,
    fs.avg_supply_cost
FROM 
    TopCustomers tc
LEFT JOIN 
    FilteredSuppliers fs ON fs.avg_supply_cost = (SELECT max_supply_cost FROM MaxAvgSupplyCost)
WHERE 
    tc.total_revenue > 10000
ORDER BY 
    tc.total_revenue DESC;
