WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS num_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
LineItemStatistics AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_price,
        COUNT(DISTINCT l.l_partkey) AS total_items,
        l.l_returnflag
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey, l.l_returnflag
)
SELECT 
    c.c_name,
    s.s_name,
    COALESCE(cs.total_spent, 0) AS customer_spending,
    ss.total_cost,
    ls.total_line_price,
    ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY COALESCE(cs.order_count, 0) DESC) AS rank
FROM 
    CustomerOrders cs
FULL OUTER JOIN 
    SupplierStats ss ON cs.c_custkey = ss.s_suppkey
JOIN 
    LineItemStatistics ls ON ls.l_orderkey = cs.order_count
JOIN 
    customer c ON cs.c_custkey = c.c_custkey
JOIN 
    supplier s ON ss.s_suppkey = s.s_suppkey
WHERE 
    (ss.total_cost IS NOT NULL OR cs.total_spent > 100)
    AND (ls.total_line_price IS NOT NULL AND ls.total_line_price > 5000)
ORDER BY 
    cs.total_spent DESC, ss.total_cost ASC;
