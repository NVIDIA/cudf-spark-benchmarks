WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
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
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_linenumber) AS total_lines
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
CustomerPerformance AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(SUM(os.total_revenue), 0) AS revenue,
        COUNT(os.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        OrderSummary os ON c.c_custkey = os.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
NationSupplier AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(ss.total_available) AS total_avail_by_nation
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        SupplierStats ss ON s.s_suppkey = ss.s_suppkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    cp.c_custkey,
    cp.c_name,
    np.n_name,
    cp.revenue,
    CASE 
        WHEN cp.order_count > 100 THEN 'High Volume'
        WHEN cp.order_count BETWEEN 50 AND 100 THEN 'Medium Volume'
        ELSE 'Low Volume'
    END AS order_volume_category,
    ns.total_avail_by_nation,
    RANK() OVER (PARTITION BY np.n_nationkey ORDER BY cp.revenue DESC) AS revenue_rank
FROM 
    CustomerPerformance cp
JOIN 
    customer c ON cp.c_custkey = c.c_custkey
LEFT JOIN 
    nation np ON c.c_nationkey = np.n_nationkey
LEFT JOIN 
    NationSupplier ns ON np.n_nationkey = ns.n_nationkey
WHERE 
    cp.revenue > 1000000
ORDER BY 
    np.n_name, cp.revenue DESC;