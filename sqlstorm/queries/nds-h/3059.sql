
WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT l.l_orderkey) AS order_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey
),
RegionSummary AS (
    SELECT 
        n.n_nationkey,
        r.r_regionkey,
        SUM(o.o_totalprice) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        n.n_nationkey, r.r_regionkey
),
CombinedStats AS (
    SELECT 
        ss.s_suppkey,
        ss.total_supply_cost,
        rs.total_sales,
        rs.total_orders
    FROM 
        SupplierStats ss
    FULL OUTER JOIN 
        RegionSummary rs ON ss.s_suppkey = (SELECT MIN(s_suppkey) FROM supplier) 
)
SELECT 
    cs.s_suppkey,
    COALESCE(cs.total_supply_cost, 0) AS supply_cost,
    COALESCE(cs.total_sales, 0) AS sales,
    ROUND(COALESCE(cs.total_sales, 0) - COALESCE(cs.total_supply_cost, 0), 2) AS profit,
    RANK() OVER (ORDER BY ROUND(COALESCE(cs.total_sales, 0) - COALESCE(cs.total_supply_cost, 0), 2) DESC) AS sales_rank
FROM 
    CombinedStats cs
WHERE 
    (cs.total_sales > 100000 OR cs.total_supply_cost > 50000)
    AND cs.s_suppkey IS NOT NULL
ORDER BY 
    profit DESC, sales_rank
LIMIT 10;
