WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        MAX(ps.ps_supplycost) AS max_supply_cost,
        MIN(ps.ps_supplycost) AS min_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(*) AS total_items,
        o.o_orderdate
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1996-01-01' AND 
        o.o_orderdate < '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_custkey, o.o_orderdate
),
CustomerRanked AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        DENSE_RANK() OVER (ORDER BY SUM(os.total_revenue) DESC) AS revenue_rank
    FROM 
        customer c
    JOIN 
        OrderStats os ON c.c_custkey = os.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    cs.s_name,
    cs.total_avail_qty,
    cs.avg_supply_cost,
    cr.c_name,
    cr.revenue_rank,
    CASE 
        WHEN cs.avg_supply_cost > 1000 THEN 'High'
        WHEN cs.avg_supply_cost BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low' 
    END AS cost_category
FROM 
    SupplierStats cs
JOIN 
    partsupp ps ON cs.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    CustomerRanked cr ON cr.revenue_rank = 1
WHERE 
    ps.ps_availqty > 0 
    AND cs.total_avail_qty > (
        SELECT AVG(total_avail_qty)
        FROM SupplierStats
        WHERE total_avail_qty IS NOT NULL
    )
ORDER BY 
    cs.total_avail_qty DESC;