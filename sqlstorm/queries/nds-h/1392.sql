WITH RankedSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) as rank
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
TopParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        (ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COALESCE(rs.total_revenue, 0) AS revenue
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN 
        RankedSales rs ON p.p_partkey = rs.p_partkey AND rs.rank = 1
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
FinalReport AS (
    SELECT 
        tp.p_partkey,
        tp.p_name,
        tp.ps_availqty,
        tp.total_cost,
        tp.revenue,
        COALESCE(co.order_count, 0) AS order_count,
        COALESCE(co.total_spent, 0) AS total_spent,
        CASE
            WHEN tp.revenue > 0 THEN 'Profitable'
            ELSE 'Unprofitable'
        END AS profitability
    FROM 
        TopParts tp
    LEFT JOIN 
        CustomerOrders co ON tp.p_partkey = co.c_custkey
)
SELECT 
    f.p_partkey,
    f.p_name,
    f.ps_availqty,
    f.total_cost,
    f.revenue,
    f.order_count,
    f.total_spent,
    f.profitability
FROM 
    FinalReport f
WHERE 
    f.total_cost > 0 AND
    (f.revenue / NULLIF(f.total_cost, 0) > 1 OR f.order_count > 10)
ORDER BY 
    profitability DESC, 
    revenue DESC;
