
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY DATE_TRUNC('month', o.o_orderdate) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
SupplierRevenue AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighRevenueOrders AS (
    SELECT 
        r.o_orderkey,
        r.total_revenue,
        c.c_nationkey AS regionkey
    FROM 
        RankedOrders r
    JOIN 
        orders o ON r.o_orderkey = o.o_orderkey
    JOIN
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region re ON n.n_regionkey = re.r_regionkey
    WHERE 
        r.revenue_rank <= 5
),
FinalReport AS (
    SELECT 
        h.o_orderkey,
        h.total_revenue,
        s.s_name,
        COALESCE(s.total_supply_cost, 0) AS total_supply_cost
    FROM 
        HighRevenueOrders h
    FULL OUTER JOIN 
        SupplierRevenue s ON h.o_orderkey = s.s_suppkey
)
SELECT 
    f.o_orderkey,
    f.total_revenue,
    f.s_name,
    f.total_supply_cost,
    CASE 
        WHEN f.total_supply_cost = 0 THEN 'No Supplier' 
        ELSE 'Has Supplier' 
    END AS supplier_status
FROM 
    FinalReport f
ORDER BY 
    f.total_revenue DESC;
