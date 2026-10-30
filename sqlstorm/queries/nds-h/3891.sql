WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
TotalOrders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
RecentOrderCount AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey 
        AND o.o_orderdate >= cast('1998-10-01' as date) - INTERVAL '1 YEAR'
    GROUP BY 
        c.c_custkey
)
SELECT 
    r.s_suppkey,
    r.s_name,
    t.total_spent,
    o.order_count,
    CASE 
        WHEN o.order_count > 5 THEN 'Frequent'
        WHEN o.order_count BETWEEN 2 AND 5 THEN 'Occasional'
        ELSE 'Rare'
    END AS customer_type
FROM 
    RankedSuppliers r
LEFT JOIN 
    TotalOrders t ON t.c_custkey = r.s_suppkey
LEFT JOIN 
    RecentOrderCount o ON o.c_custkey = r.s_suppkey
WHERE 
    r.rank = 1 
    AND t.total_spent IS NOT NULL
ORDER BY 
    t.total_spent DESC NULLS LAST
LIMIT 10;