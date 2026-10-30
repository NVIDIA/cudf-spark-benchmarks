
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_type ORDER BY s.s_acctbal DESC) AS acct_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
AggregateOrders AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderstatus IN ('O', 'F')
    GROUP BY 
        o.o_orderkey
),
CustomerStats AS (
    SELECT 
        c.c_custkey,
        AVG(o.total_revenue) AS avg_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        AggregateOrders o ON c.c_custkey = o.o_orderkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    cs.c_custkey,
    cs.avg_revenue,
    CASE 
        WHEN cs.order_count > 10 THEN 'High Value'
        WHEN cs.order_count BETWEEN 5 AND 10 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value,
    rs.s_name,
    rs.acct_rank
FROM 
    CustomerStats cs
LEFT JOIN 
    RankedSuppliers rs ON cs.avg_revenue > COALESCE((SELECT AVG(total_revenue) FROM AggregateOrders), 0)
WHERE 
    cs.avg_revenue IS NOT NULL 
    AND rs.acct_rank = 1
ORDER BY 
    cs.avg_revenue DESC NULLS LAST;
