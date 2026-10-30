WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        RANK() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS cost_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_orderkey) AS line_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopOrders AS (
    SELECT 
        od.o_orderdate,
        SUM(od.total_revenue) AS monthly_revenue
    FROM 
        OrderSummary od
    WHERE 
        od.o_orderdate >= DATE '1995-01-01' AND od.o_orderdate < DATE '1996-01-01'
    GROUP BY 
        od.o_orderdate
),
SupplierRevenue AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        COALESCE(SUM(od.total_revenue), 0) AS total_revenue
    FROM 
        SupplierSummary s
    LEFT JOIN 
        lineitem l ON l.l_suppkey = s.s_suppkey
    LEFT JOIN 
        OrderSummary od ON l.l_orderkey = od.o_orderkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    sr.s_name,
    sr.total_revenue,
    ss.total_cost,
    ss.part_count,
    (sr.total_revenue - ss.total_cost) AS profit,
    CASE 
        WHEN sr.total_revenue > ss.total_cost THEN 'Profitable'
        ELSE 'Unprofitable'
    END AS profitability_status
FROM 
    SupplierRevenue sr
JOIN 
    SupplierSummary ss ON sr.s_suppkey = ss.s_suppkey
WHERE 
    ss.cost_rank <= 10
ORDER BY 
    profit DESC;