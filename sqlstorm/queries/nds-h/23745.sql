WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        p.p_retailprice IS NOT NULL
),
SupplierAvgCost AS (
    SELECT 
        ps.ps_partkey,
        AVG(ps.ps_supplycost) AS avg_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
CompositeResult AS (
    SELECT 
        n.n_name,
        COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) AS return_count,
        AVG(sac.avg_cost) AS average_supply_cost,
        RANK() OVER (ORDER BY COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) DESC) AS revenue_rank
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    LEFT JOIN 
        SupplierAvgCost sac ON ps.ps_partkey = sac.ps_partkey
    GROUP BY 
        n.n_name
)
SELECT 
    cr.n_name,
    cr.total_revenue,
    cr.order_count,
    cr.return_count,
    cr.average_supply_cost,
    CASE 
        WHEN cr.revenue_rank <= 5 THEN 'High Performer'
        WHEN cr.revenue_rank <= 10 THEN 'Medium Performer'
        ELSE 'Low Performer'
    END AS performance_category
FROM 
    CompositeResult cr
WHERE 
    cr.total_revenue IS NOT NULL 
    AND cr.total_revenue > (SELECT AVG(total_revenue) FROM CompositeResult)
ORDER BY 
    cr.total_revenue DESC
LIMIT 10;
