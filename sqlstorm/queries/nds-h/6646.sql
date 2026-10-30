WITH TotalSales AS (
    SELECT 
        l.l_shipmode,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1998-01-01'
    GROUP BY 
        l.l_shipmode
), 
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    t.l_shipmode,
    t.total_revenue,
    s.s_name,
    s.total_supply_cost,
    (t.total_revenue / NULLIF(s.total_supply_cost, 0)) AS revenue_supply_ratio
FROM 
    TotalSales t
JOIN 
    SupplierStats s ON t.l_shipmode = s.s_name
ORDER BY 
    revenue_supply_ratio DESC
LIMIT 10;